require 'statue/version'

require 'statue/backends'
require 'statue/metric'
require 'statue/stopwatch'

module Statue
  extend self

  attr_accessor :namespace
  attr_accessor :logger
  attr_writer :backend

  def report_duration(metric_name, duration = nil, **options, &block)
    result = nil
    backend << Metric.measure(metric_name, duration: duration, **options) do
      result = block.call
    end
    result
  end

  def report_increment(metric_name, value = 1, **options)
    backend << Metric.counter(metric_name, value, **options)
  end

  def report_gauge(metric_name, value, **options)
    backend << Metric.gauge(metric_name, value, **options)
  end

  def report_success_or_failure(metric_name, success_method: nil, **options, &block)
    result  = block.call

    success = success_method ? result.public_send(success_method) : result
    report_increment("#{metric_name}.#{success ? "success" : "failure"}", **options)

    result
  rescue
    report_increment("#{metric_name}.failure", **options)
    raise
  end

  def stopwatch(metric_name)
    Stopwatch.new(name: metric_name, reporter: self)
  end

  def backend
    @backend ||= UDPBackend.from_uri("statsd://127.0.0.1:8125")
  end

  def debug(text, &block)
    logger.debug(text, &block) if logger
  end

  def error(text, &block)
    logger.error(text, &block) if logger
  end

end
