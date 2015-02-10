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
