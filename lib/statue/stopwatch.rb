module Statue
  class Stopwatch

    def initialize(name:, now: Clock.now_in_ms, reporter: Statue)
      @reporter = reporter
      @name     = name
      @start    = @partial = now
    end

    def partial(suffix = nil, now: Clock.now_in_ms, **options)
      previous, @partial = @partial, now

      @reporter.report_duration(metric_name(suffix || "runtime.partial"), @partial - previous, **options)
    end

    def stop(suffix = nil, now: Clock.now_in_ms, report_partial: false, **options)
      partial(report_partial.is_a?(String) ? report_partial : nil, now: now, **options) if report_partial

      previous, @start = @start, now

      @reporter.report_duration(metric_name(suffix || "runtime.total"), @start - previous, **options)
    end

    def reset(now: Clock.now_in_ms)
      @start = @partial = now
    end

    private

    def metric_name(suffix)
      "#{@name}.#{suffix}"
    end

  end
end
