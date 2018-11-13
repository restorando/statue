require 'test_helper'
require 'statue/sidekiq_statistics'
require 'sidekiq/testing'

describe Statue::SidekiqStatistics do
  let(:metrics) { Statue.backend.captures }

  Sidekiq::Testing.inline!

  # around do |example|
  #   Sidekiq::Testing.inline! do
  #     example.call
  #   end
  # end

  # before do
  #   Sidekiq::Testing.inline! do
  #     example.call
  #   end
  # end

  after do
    # Sidekiq::Testing.inline! do
    #   example.call
    # end

    Statue.backend.captures.clear
  end

  class FooJob
    include Sidekiq::Worker

    # queue "statue-default"

    def job_name(*_args)
      self.class.name.gsub(/::/, "-")
    end

    attr_accessor :should_fail

    def perform
      raise "fail" if should_fail
    end
  end

  it "allows arbitrary event counting" do
    Statue::SidekiqStatistics.count_event("test", FooJob.new, "queue" => "queue")

    assert_equal(metrics.size, 1)
    assert_equal(metrics.first.name, "job.queue.FooJob.test")
    assert_equal(metrics.first.type, :c)
  end

  describe "Sidekiq Middleware" do
    let(:worker) { FooJob.new }
    let(:middleware) { Statue::SidekiqStatistics::SidekiqMiddleware.new }
    let(:msg) { { "enqueued_at" => Time.now.to_f, "queue" => "default" } }

    it "tracks job performance" do
      # expect(Statue::Clock).to receive(:duration_in_ms).and_return(5)

      assert_send([Statue::Clock, :duration_in_ms, 5])

      middleware.call(worker, msg, msg["queue"]) { nil }

      performance = metrics.find { |m| m.name == "job.default.FooJob" }
      assert_equal(performance.type, :ms)
      assert_equal(performance.value, 5)
    end

    it "counts block call always as a success" do
      middleware.call(worker, msg, msg["queue"]) { false }

      success = metrics.find { |m| m.name == "job.default.FooJob.success" }
      assert_equal(success.type, :c)
    end

    it "counts exceptions as job failure" do
      # expect {
      #   middleware.call(worker, msg, msg["queue"]) { raise "a" }
      # }.to raise_error("a")

      assert_raises("a") {
        middleware.call(worker, msg, msg["queue"]) { raise "a" }
      }

      success = metrics.find { |m| m.name == "job.default.FooJob.success" }
      assert_nil(success)

      failure = metrics.find { |m| m.name == "job.default.FooJob.failure" }
      assert_equal(failure.type, :c)
    end

    it "counts retries as job failure" do
      msg["retry_count"] = 1
      middleware.call(worker, msg, msg["queue"]) { true }

      retry_metric = metrics.find { |m| m.name == "job.default.FooJob.retry" }
      assert_equal(retry_metric.type, :c)
    end

    it "tracks queue latency" do
      # Time - 1 minute
      msg["enqueued_at"] = Time.now - 60

      middleware.call(worker, msg, msg["queue"]) { nil }

      latency = metrics.find { |m| m.name == "job.default.FooJob.latency" }
      assert_equal(latency.type, :ms)
      assert_in_delta(latency.value, 60, delta = 0.001)
    end
  end
end
