require 'test_helper'

describe Statue::Stopwatch do
  after do
    Statue.backend.captures.clear
  end

  describe "#partial" do
    it "reports the duration between start and the partial call" do
      stopwatch = Statue::Stopwatch.new(name: "my_watch", now: 0)
      stopwatch.partial(now: 42) # 42 milliseconds after

      assert_equal 1, Statue.backend.captures.size
      assert_equal "my_watch.runtime.partial:42|ms", Statue.backend.captures.first.to_s
    end

    it "can report multiple partials" do
      stopwatch = Statue::Stopwatch.new(name: "my_watch", now: 0)
      (1..20).each { |now| stopwatch.partial(now: now) }

      assert_equal 20, Statue.backend.captures.size
      Statue.backend.captures.each do |metric|
        assert_equal "my_watch.runtime.partial:1|ms", metric.to_s
      end
    end

    it "tracks time correctly" do
      stopwatch = Statue::Stopwatch.new(name: "my_watch")
      stopwatch.partial

      assert Statue.backend.captures.first.value > 0, "partial metric time should be greater than zero"
    end
  end

  describe "#stop" do
    it "reports the duration between start and the stop call" do
      stopwatch = Statue::Stopwatch.new(name: "my_watch", now: 0)
      stopwatch.stop(now: 42)

      assert_equal 1, Statue.backend.captures.size
      assert_equal "my_watch.runtime.total:42|ms", Statue.backend.captures.first.to_s
    end

    it "is not affected by partials" do
      stopwatch = Statue::Stopwatch.new(name: "my_watch", now: 0)
      (1..20).each { |now| stopwatch.partial(now: now) }
      stopwatch.stop(now: 21)

      assert_equal 21, Statue.backend.captures.size
      *_partials, total = Statue.backend.captures
      assert_equal "my_watch.runtime.total:21|ms", total.to_s
    end

    it "can send the last partial duration" do
      stopwatch = Statue::Stopwatch.new(name: "my_watch", now: 0)
      (1..20).each { |now| stopwatch.partial(now: now) }
      stopwatch.stop(now: 21, report_partial: true)

      assert_equal 22, Statue.backend.captures.size
      *partials, total = Statue.backend.captures
      assert_equal "my_watch.runtime.total:21|ms", total.to_s
      partials.each do |metric|
        assert_equal "my_watch.runtime.partial:1|ms", metric.to_s
      end
    end

    it "can send the last partial duration with a special name" do
      stopwatch = Statue::Stopwatch.new(name: "my_watch", now: 0)
      (1..20).each { |now| stopwatch.partial(now: now) }
      stopwatch.stop(now: 21, report_partial: "runtime.final_lap")

      assert_equal 22, Statue.backend.captures.size
      *_partials, special_partial, _total = Statue.backend.captures
      assert_equal "my_watch.runtime.final_lap:1|ms", special_partial.to_s
    end

    it "tracks time correctly" do
      stopwatch = Statue::Stopwatch.new(name: "my_watch")
      stopwatch.stop

      assert Statue.backend.captures.first.value > 0, "partial metric time should be greater than zero"
    end
  end

end
