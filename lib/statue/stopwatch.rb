module Statue
  class Stopwatch

    def initialize(name:, now: clock_now, reporter: Statue)
      @reporter = reporter
      @name     = name
      @start    = @partial = now
    end

    def partial(suffix = nil, now: clock_now, **options)
      previous, @partial = @partial, now

      @reporter.report_duration(metric_name(suffix || "runtime.partial"), @partial - previous, **options)
    end

    def stop(suffix = nil, now: clock_now, report_partial: false, **options)
      partial(report_partial.is_a?(String) ? report_partial : nil, now: now, **options) if report_partial

      previous, @start = @start, now

      @reporter.report_duration(metric_name(suffix || "runtime.total"), @start - previous, **options)
    end

    def reset(now: clock_now)
      @start = @partial = now
    end

    private

    def metric_name(suffix)
      "#{@name}.#{suffix}"
    end

    def clock_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

  end
end
