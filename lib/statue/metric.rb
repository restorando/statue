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

    def self.counter(name, value = 1, options = {})
      new(options.merge(type: :c, value: value, name: name))
    end

    def self.gauge(name, value, options = {})
      new(options.merge(type: :g, value: value, name: name))
    end

    def self.measure(name, options = {}, &block)
      duration = options.delete(:duration)
      value = duration || Statue::Clock.duration_in_ms(&block)
      new(options.merge(type: :ms, value: value, name: name))
    end

    def initialize(options = {})
      @type  = options.fetch(:type)
      @name  = options.fetch(:name)
      @value = options.fetch(:value)
      @type_description = TYPES[type] or raise ArgumentError, "invalid type: #{type}"
      @sample_rate = options[:sample_rate] || 1.0
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
