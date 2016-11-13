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

    def self.counter(name, value = 1, options = {})
      new(options.merge(type: :c, value: value, name: name))
    end

    def self.gauge(name, value, options = {})
      new(options.merge(type: :g, value: value, name: name))
    end

    def self.measure(name, options = {}, &block)
      duration = options.delete(:duration)
      value = duration || Statue.duration(&block)
      new(options.merge(type: :ms, value: value, name: name))
    end

    def initialize(options = {})
      @type  = options.fetch(:type)
      @name  = options.fetch(:name)
      @value = options.fetch(:value)
      @sample_rate = options[:sample_rate] || 1.0
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
