# Statue

![Build Status](https://travis-ci.org/restorando/statue.svg?branch=master)

    / ___)(_  _)/ _\(_  _)/ )( \(  __)
    \___ \  )( /    \ )(  ) \/ ( ) _)
    (____/ (__)\_/\_/(__) \____/(____)
Rock solid metrics report...

Easily track application metrics into [Statsite](https://github.com/armon/statsite) (Statsd compatible).

## Configuration

The library has different backends, one to be used for production environment (ie. actually
 sending metrics using the Statsd protocol), and the others for testing or developing.

The available backends are:

`Statue::UDPBackend` -> this is the one that actually sends metrics to the Statsd.

eg.
```ruby
Statue.backend = Statue::UDPBackend.new(statsd_host, statsd_port)
```

`Statue::NullBackend`, this backend discards all metrics (useful for test environment, if you
aren't interested in testing which metrics are sent).

`Statue::CaptureBackend`, this backend collects all metrics (useful for test environment, if you
arent interested in testing which metrics are sent). You can check the metrics with `Statue.backend.captures`
and reset this array with `Statue.backend.captures.clear` or by setting a new instance before each test.

`Statue::LoggerBackend`, this backend logs the received metrics to a logger (useful for development purposes)

eg.
```ruby
Statue.backend = Statue::LoggerBackend.new(Rails.logger)
```

## Usage

### Common meassurments

`Statue.report_increment('metric.name')` -> send to Statsd an increment to the counter `metric.name`

`Statue.report_gauge('metric.name', value)` -> send to Statsd the gauge value for `metric.name`

`Statue.report_duration('metric.name') { some_operation } # => some_operation_result` -> send to Statsd the
measure for the block duration in `metric.name`

`Statue.report_success_or_failure('metric.name') { some_operation } # => some_operation_result` -> checks the
result of the block, if its a `truthy` value, then increments `metric.name.success`, else it increments
`metric.name.failure`.

### Stopwatch

The stopwatch provides an easy way to track the duration of a long process with multiple phases.

```ruby
stopwatch = Statue.stopwatch("metric") # => Starts tracking time

while something do
  do_something
  stopwatch.partial # => reports duration from last partial until now as: "metric.runtime.partial"
end

stopwatch.stop # => reports duration from start until now as: "metric.runtime.total"
```

### Rack Integration

We provide a middleware to track basic request metrics, see: Statue::RackStatistics

## Contributing

1. Fork it ( https://github.com/restorando/statue/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
