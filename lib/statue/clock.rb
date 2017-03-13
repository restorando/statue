module Statue
  module Clock
    extend self

    def now_in_ms
      Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1_000
    end

    def duration_in_ms
      start = now_in_ms
      yield
      now_in_ms - start
    end

  end
end
