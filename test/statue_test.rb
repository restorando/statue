require 'test_helper'

describe Statue do
  after do
    Statue.backend.captures.clear
  end

  describe ".report_increment" do
    it "Adds a counter metric to the backend" do
      Statue.report_increment("some.counter")

      assert_equal 1, Statue.backend.captures.size
      assert_equal "some.counter:1|c", Statue.backend.captures.first.to_s
    end

    it "Allows to increment by a custom value" do
      Statue.report_increment("some.counter", 5)

      assert_equal 1, Statue.backend.captures.size
      assert_equal "some.counter:5|c", Statue.backend.captures.first.to_s
    end
  end

  describe ".report_duration" do

    it "adds a measure metric to the backend using the block call duration" do
      Statue::Clock.stub(:duration_in_ms, 1.5) do
        _result = Statue.report_duration("some.timer") { nil }

        assert_equal 1, Statue.backend.captures.size
        assert_equal "some.timer:1.5|ms", Statue.backend.captures.first.to_s
      end
    end

    it "returns the block result" do
      result = Statue.report_duration("some.timer") { 42 }

      assert_equal 42, result
    end

    it "adds a measure metric to the backend using the fixed value" do
      _result = Statue.report_duration("some.timer", 2.5)

      assert_equal 1, Statue.backend.captures.size
      assert_equal "some.timer:2.5|ms", Statue.backend.captures.first.to_s
    end

    it "doesn't report duration if an exception is thrown" do
      begin
        Statue.report_duration("some.timer") { raise "error" }
      rescue => e
        assert_equal "error", e.message
        assert_empty Statue.backend.captures
      end
    end

  end

  describe ".report_gauge" do

    it "adds a gauge metric to the backend using the fixed value" do
      _result = Statue.report_gauge("some.gauge", 23)

      assert_equal 1, Statue.backend.captures.size
      assert_equal "some.gauge:23|g", Statue.backend.captures.first.to_s
    end

  end

  describe ".report_success_or_failure" do

    it "Adds a counter metric to the backend with .success suffix with a truthy result" do
      Statue.report_success_or_failure("some.event") { 42 }

      assert_equal 1, Statue.backend.captures.size
      assert_equal "some.event.success:1|c", Statue.backend.captures.first.to_s
    end

    it "Adds a counter metric to the backend with .failure suffix with a falsey result" do
      Statue.report_success_or_failure("some.event") { nil }

      assert_equal 1, Statue.backend.captures.size
      assert_equal "some.event.failure:1|c", Statue.backend.captures.first.to_s
    end

    it "returns the block result" do
      result = Statue.report_success_or_failure("some.event") { 42 }

      assert_equal 42, result
    end

    it "Adds a counter metric to the backend with .failure suffix when an exception ocurrs" do
      begin
        Statue.report_success_or_failure("some.event") { raise "error" }
      rescue => e
        assert_equal "error", e.message
        assert_equal 1, Statue.backend.captures.size
        assert_equal "some.event.failure:1|c", Statue.backend.captures.first.to_s
      end
    end

    it "allows to use a symbol for a custom success_method" do
      Statue.report_success_or_failure("some.zero_event", success_method: :zero?) { 0 }
      Statue.report_success_or_failure("some.life_event", success_method: :zero?) { 42 }
      zero_event, life_event = Statue.backend.captures

      assert_equal 2, Statue.backend.captures.size
      assert_equal "some.zero_event.success:1|c", zero_event.to_s
      assert_equal "some.life_event.failure:1|c", life_event.to_s
    end

  end

end
