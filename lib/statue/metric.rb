require 'statue/clock'

module Statue
  class Metric
    TYPES = {
      c:  'increment',
      ms: 'measure',
      g:  'gauge',
      kv: 'key/value',
      s:  'set'
    }

    attr_accessor :type, :name, :value, :sample_rate
    attr_reader :full_name, :type_description

    def self.counter(name, value = 1, **options)
      new(type: :c, value: value, name: name, **options)
    end

    def self.gauge(name, value, **options)
      new(type: :g, value: value, name: name, **options)
    end

    def self.measure(name, duration: nil, **options, &block)
      value = duration || Statue::Clock.duration_in_ms(&block)
      new(type: :ms, value: value, name: name, **options)
    end

    def initialize(type:, name:, value:, sample_rate: 1.0)
      @type_description = TYPES[type] or raise ArgumentError, "invalid type: #{type}"
      @type  = type
      @name  = name
      @value = value
      @sample_rate = sample_rate
      @full_name   = Statue.namespace ? "#{Statue.namespace}.#{@name}" : @name
    end

    def to_s
      str = "#{full_name}:#{value}|#{type}"
      str << "|@#{sample_rate}" if sample_rate != 1.0
      str
    end

    def inspect
      "#<StatsD::Instrument::Metric #{full_name} #{type_description}(#{value})@#{sample_rate}>"
    end

  end
end
