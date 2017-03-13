require 'test_helper'
require 'statue/rack_statistics'
require 'rack/test'

describe Statue::RackStatistics do
  include Rack::Test::Methods
  def app
    Statue::RackStatistics.new(App.new)
  end

  def find_metric(name)
    Statue.backend.captures.find { |m| m.name == name }
  end

  class App
    def call(env)
      raise "Uncaught error" if env['raise_error']
      [
        env['status'] || 200,
        {},
        []
      ]
    end
  end

  after do
    Statue.backend.captures.clear
  end

  describe "request statistics on normal processing" do

    it "sends queue time" do
      header "X-Request-Start", "t=#{Time.now.to_f - 1}"
      get "/"

      queue_time = find_metric("request.queue")
      assert queue_time, "Didn't report queue time"
      assert_equal "measure", queue_time.type_description

      # Measured time can't be less than 1000 ms because we set it to 1 sec before now.
      # Allow a range of 30ms for ruby to do processing and avoid false positives
      assert_in_delta 1015, queue_time.value, 15 # within range 1000-1030
    end

    it "sends request runtime" do
      get "/"

      runtime_time = find_metric("request.GET.root.runtime")
      assert runtime_time, "Didn't report request runtime"
      assert_equal "measure", runtime_time.type_description
      # Allow a range of 30ms for ruby to do processing and avoid false positives
      assert_in_delta 15, runtime_time.value, 15 # within range 1000-1030
    end

    it "sends counter for status-xxx" do
      get "/"

      runtime_time = find_metric("request.GET.root.status-200")
      assert runtime_time, "Didn't report status-200 counter"
      assert_equal "increment", runtime_time.type_description
      assert_equal 1, runtime_time.value
    end

    it "sends counter for status group" do
      get "/"

      runtime_time = find_metric("request.GET.root.success")
      assert runtime_time, "Didn't report sucess counter"
      assert_equal "increment", runtime_time.type_description
      assert_equal 1, runtime_time.value
    end

    it "sends counter for other status codes" do
      get "/", {}, { 'status' => 502 }

      runtime_time = find_metric("request.GET.root.status-502")
      assert runtime_time, "Didn't report status-502 counter"
      assert_equal "increment", runtime_time.type_description
      assert_equal 1, runtime_time.value
    end

    it "sends counter for other status groups" do
      get "/", {}, { 'status' => 502 }

      runtime_time = find_metric("request.GET.root.error")
      assert runtime_time, "Didn't report error counter"
      assert_equal "increment", runtime_time.type_description
      assert_equal 1, runtime_time.value
    end

    it "sends all metrics and only those" do
      header "X-Request-Start", "t=#{Time.now.to_f}"
      get "/"

      metrics = Statue.backend.captures.map(&:name)
      expected_metrics = %w[
        request.queue
        request.GET.root.runtime
        request.GET.root.status-200
        request.GET.root.success
      ]
      missing = expected_metrics - metrics
      extra   = metrics - expected_metrics

      assert missing.empty?, "expect not to be missing, but these were missing: #{missing.inspect}"
      assert extra.empty?, "expected no other metric to be found, but found these: #{extra.inspect}"
    end

  end

  describe "request statistics on normal processing" do

    it "sends queue time" do
      header "X-Request-Start", "t=#{Time.now.to_f - 1}"
      assert_raises do
        get "/", {}, { 'raise_error' => true }
      end

      queue_time = find_metric("request.queue")
      assert queue_time, "Didn't report queue time"
      assert_equal "measure", queue_time.type_description

      # Measured time can't be less than 1000 ms because we set it to 1 sec before now.
      # Allow a range of 30ms for ruby to do processing and avoid false positives
      assert_in_delta 1015, queue_time.value, 15 # within range 1000-1030
    end

    it "sends counter for other status codes" do
      assert_raises do
        get "/", {}, { 'raise_error' => true }
      end

      runtime_time = find_metric("request.GET.root.unhandled-exception")
      assert runtime_time, "Didn't report unhandled-exception counter"
      assert_equal "increment", runtime_time.type_description
      assert_equal 1, runtime_time.value
    end

  end
end
