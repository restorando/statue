## [0.4.1] - 2017-03-15

### Documentation

- Added a simple example to the README.md detailing how to use the new `SidekiqStatistics` middleware.

## [0.4.0] - 2017-03-13

### Feature

- Added `SidekiqStatistics` middleware support
- To integrate it with your middleware, just add it to your sidekiq's initializer like follows:

```ruby
  config.server_middleware do |chain|
    chain.add Statue::SidekiqStatistics::SidekiqMiddleware
  end
```

## [0.3.0] - 2017-03-13

### Feature

- Extract duration measuring to `Statue::Clock` and be explicit that we are handling milliseconds.
- `RackStatistics` queue time is now taken from `X-Request-Start` header.

### Backward incompatible changes

- All duration reports are now sent in milliseconds (as it should have always been). These includes:
  - `Statue.report_duration`
  - `RackStatistics` middleware metrics
  - `Statue.stopwatch`
- Removed `Statue.duration`, you should use `Statue::Clock.duration_in_ms` (which is more explicit)
- `RackStatistics`: `request.<key>` metric was renamed to `request.<key>.runtime` to have more uniform names
- `RackStatistics`: now sends specific counter for when your application didn't handle the exception
- `UDPBacked`: now receives host/port named params or can be built from a string with
  `UDPBacked.from_uri(<uri>)`

## [0.2.7] - 2016-03-09

## Fixes

- Make UDPBacked compatible with JRuby

## [0.2.4] - 2016-02-04

## Features

- Add support for gauges

## [0.2.2] - 2016-02-02

## Fixes

- Allow RackStatistics to handle not integer status codes

## [0.2.1] - 2016-01-07

## Features

- Add stopwatchs to report multiple partial times

## [0.2.0] - 2015-11-17

### Features

- Add support for multithreaded applications
