require 'statue/version'

require 'statue/backends'
require 'statue/metric'

module Statue
  extend self

  attr_accessor :namespace, :logger

  attr_accessor :backend

  def report_duration(metric_name, **options, &block)
    result = nil
    backend << Metric.measure(metric_name, **options) do
      result = block.call
    end
    result
  end

  def report_increment(metric_name, **options)
    backend << Metric.counter(metric_name, **options)
  end

  def report_success_or_failure(metric_name, success_method: nil, **options, &block)
    result  = block.call
    success = success_method ? result.public_send(success_method) : result

    if success
      report_increment("#{metric_name}.success", **options)
    else
      report_increment("#{metric_name}.failure", **options)
    end

    result
  rescue
    report_increment("#{metric_name}.failure", **options)
    raise
  end

  def backend
    @backend ||= UDPBackend.new
  end

  def duration
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end

  def debug(text, &block)
    logger.debug(text, &block) if logger
  end

  def error(text, &block)
    logger.error(text, &block) if logger
  end

end
