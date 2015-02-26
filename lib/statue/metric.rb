module Statue
  class Metric
    TYPES = {
      c:  'increment',
      ms: 'measure',
      g:  'gauge',
      kv: 'key/value',
      s:  'set',
    }

    attr_accessor :type, :name, :value, :sample_rate

    def self.counter(name, value = 1, **options)
      new(type: :c, value: value, name: name, **options)
    end

    def self.measure(name, duration: nil, **options, &block)
      value = duration || Statue.duration(&block)
      new(type: :ms, value: value, name: name, **options)
    end

    def initialize(type:, name:, value:, sample_rate: 1.0)
      @type  = type
      @name  = name
      @value = value
      @sample_rate = sample_rate
    end

    def to_s
      str = "#{full_name}:#{value}|#{type}"
      str << "|@#{sample_rate}" if sample_rate != 1.0
      str
    end

    def inspect
      "#<StatsD::Instrument::Metric #{full_name} #{TYPES[type]}(#{value})@#{sample_rate}>"
    end

    def full_name
      if Statue.namespace
        "#{Statue.namespace}.#{@name}"
      else
        @name
      end
    end

  end
end
