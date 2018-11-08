require 'statue'

module Statue
  # This module simplifies the job statistics tracking using Statue
  # * Provides a SidekiqMiddleware (to track performance and latency)
  # * Provides a method for tracking other middleware events (eg. throttling, deadline)
  #
  # The current set of metrics are:
  #
  # * count job.<queue>.<job_name>.(success|failure):
  #   depending if the job succeeded or failed
  # * count job.<queue>.<job_name>.throttled:
  #   only if the job was throttled by sidekiq-throttler
  # * count job.<queue>.<job_name>.overdue:
  #   only if the deadline from run_deadline_middleware was reached
  # * count job.<queue>.<job_name>.retry:
  #   only if the job corresponds to a retry for a previously failed job
  # * duration job.<queue>.<job_name>.latency:
  #   time difference between now and when the job last entered the queue
  # * duration job.<queue>.<job_name>:
  #   job run duration (reported only if the job doesn't fail)
  module SidekiqStatistics
    def self.count_event(event, worker, message)
      Statue.report_increment("#{job_metric_name(worker, message)}.#{event}")
    end

    def self.job_metric_name(worker, message)
      job_name = if worker.respond_to?(:job_name)
        worker.job_name(*message["args"])
      else
        worker.class.name.gsub(/::/, "-")
      end
      "job.#{message["queue"]}.#{job_name}"
    end

    # Middleware for tracking common job run metrics
    class SidekiqMiddleware
      def call(worker, message, _queue)
        job_metric_name = RCore::JobStatistics.job_metric_name(worker, message)

        if message["retry_count"]
          # Count retried jobs
          Statue.report_increment("#{job_metric_name}.retry")
        else
          # Track latency for new jobs only (we can't know since when the failed job is waiting)
          enqueued_at = Time.at(message["enqueued_at"])
          Statue.report_duration("#{job_metric_name}.latency", Time.now - enqueued_at)
        end

        Statue.report_duration(job_metric_name) do
          Statue.report_success_or_failure(job_metric_name) do
            yield
            true # We only count exceptions as failure
          end
        end
      end
    end

    # This module is prepended in sidekiq-throttler rate_limit class
    # Wraps the exceeded block with a block that also counts the job as beeing throttled
    module ThrottlingExceeded
      def exceeded(&block)
        super do |*args|
          yield(*args)
          RCore::JobStatistics.count_event("throttled", worker, "queue" => queue, "args" => payload)
        end
      end
    end
  end
end
