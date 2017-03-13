module Statue
  class Stopwatch

    def initialize(name, options = {})
      @name     = name
      @reporter = options[:reporter] || Statue
      @start    = @partial = options[:now] || Clock.now_in_ms
    end

    def partial(options = {})
      suffix = options.delete(:suffix)
      now = options.delete(:now) || Clock.now_in_ms
      previous, @partial = @partial, now

      @reporter.report_duration(metric_name(suffix || "runtime.partial"), @partial - previous, options)
    end

    def stop(options = {})
      suffix = options.delete(:suffix)
      now = options.delete(:now) || Clock.now_in_ms
      report_partial = options.delete(:report_partial) || false

      partial(options.merge(now: now, suffix: report_partial.is_a?(String) ? report_partial : nil)) if report_partial

      previous, @start = @start, now

      @reporter.report_duration(metric_name(suffix || "runtime.total"), @start - previous, options)
    end

    def reset(options = {})
      @start = @partial = options[:now] || Clock.now_in_ms
    end

    private

    def metric_name(suffix)
      "#{@name}.#{suffix}"
    end

  end
end
