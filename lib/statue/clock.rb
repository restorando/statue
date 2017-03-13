module Statue
  module Clock
    extend self

  if defined?(Process::CLOCK_MONOTONIC)
    def now_in_ms
      Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1_000
    end
  elsif RUBY_PLATFORM == 'java'
    def now_in_ms
      java.lang.System.nanoTime() / 1_000_000.0
    end
  else
    def now_in_ms
      Time.now.to_f * 1_000
    end
  end

    def duration_in_ms
      start = now_in_ms
      yield
      now_in_ms - start
    end

  end
end
