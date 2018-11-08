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
    # expect {
    #   SidekiqStatistics.count_event("test", FooJob.new, "queue" => "queue")
    # }.to change(metrics, :size).by(1)

    expect(metrics.first.name).to eq("job.queue.Statue-FooJob.test")
    expect(metrics.first.type).to eq(:c)
  end

  describe "Sidekiq Middleware" do
    let(:worker) { FooJob.new }
    let(:middleware) { SidekiqStatistics::SidekiqMiddleware.new }
    let(:msg) { { "enqueued_at" => Time.current.to_f, "queue" => "default" } }

    it "tracks job performance" do
      expect(Statue::Clock).to receive(:duration_in_ms).and_return(5)
      middleware.call(worker, msg, msg["queue"]) { nil }

      performance = metrics.find { |m| m.name == "job.default.RCore-FooJob" }
      expect(performance.type).to eq(:ms)
      expect(performance.value).to eq(5)
    end

    it "counts block call always as a success" do
      middleware.call(worker, msg, msg["queue"]) { false }

      success = metrics.find { |m| m.name == "job.default.RCore-FooJob.success" }
      expect(success.type).to eq(:c)
    end

    it "counts exceptions as job failure" do
      # expect {
      #   middleware.call(worker, msg, msg["queue"]) { raise "a" }
      # }.to raise_error("a")

      assert_raises("a") {
        middleware.call(worker, msg, msg["queue"]) { raise "a" }
      }

      success = metrics.find { |m| m.name == "job.default.RCore-FooJob.success" }
      expect(success).to be_nil

      failure = metrics.find { |m| m.name == "job.default.RCore-FooJob.failure" }
      expect(failure.type).to eq(:c)
    end

    it "counts retries as job failure" do
      msg["retry_count"] = 1
      middleware.call(worker, msg, msg["queue"]) { true }

      retry_metric = metrics.find { |m| m.name == "job.default.RCore-FooJob.retry" }
      expect(retry_metric.type).to eq(:c)
    end

    it "tracks queue latency" do
      msg["enqueued_at"] = Time.current - 1.minute
      middleware.call(worker, msg, msg["queue"]) { nil }

      latency = metrics.find { |m| m.name == "job.default.RCore-FooJob.latency" }
      expect(latency.type).to eq(:ms)
      expect(latency.value).to be_within(0.001).of(60)
    end
  end
end
