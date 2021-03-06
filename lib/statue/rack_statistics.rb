require 'statue'

module Statue
  # Middleware to send metrics about rack requests
  #
  # this middleware reports metrics with the following pattern:
  #  `{env['REQUEST_METHOD']}.{path_name}
  #
  # where `path_name` can be configured when inserting the middleware like this:
  #   `use RackStatistics, path_name: ->(env) { ... build the path name ... }`
  # You can build the path using the environment information in the lambda or
  # you can delegate that logic to your app stack and later fetching it from
  # the env, Eg:
  #   `use RackStatistics, path_name: ->(env) { env['route.path_name'] }`
  #
  # This middleware will report the following metrics
  #
  # Counters:
  #
  # * request.<key>.status-XXX (where XXX is the status code)
  # * request.<key>.success    (on any status 2XX)
  # * request.<key>.unmodified (on status 304)
  # * request.<key>.redirect   (on any status 3XX)
  # * request.<key>.failure    (on any status 4xx)
  # * request.<key>.error      (on any status 5xx)
  # * request.<key>.unhandled-exception (when an exception is raised that your application didn't handle)
  #
  # Timers (all measured from the middleware perspective):
  #
  # * request.<key>.runtime (request time)
  # * request.queue (queue time, depends on HTTP_X_REQUEST_START header)
  #
  # To get accurate timers, the middleware should be as higher as
  # possible in your rack stack
  #
  class RackStatistics
    DEFAULT_PATH_NAME = lambda do |env|
      # Remove duplicate and trailing '/'
      path = env['PATH_INFO'].squeeze('/').chomp('/')
      if path == ''
        'root'
      else
        # Skip leading '/' and replace statsd special characters by '-'
        env['REQUEST_PATH'][1..-1].tr('/,|', '-')
      end
    end

    def initialize(app, path_name: DEFAULT_PATH_NAME)
      @app = app
      @path_name = path_name
    end

    def call(env)
      report_header_metrics(env)

      response = nil
      duration = Statue::Clock.duration_in_ms do
        response = @app.call(env)
      end

      report_response_metrics(env, response, duration)

      response
    rescue => e
      report_exception(env, e) and raise
    end

    private

    def report_header_metrics(env)
      if start_header = (env['HTTP_X_REQUEST_START'] || env['HTTP_X_QUEUE_START'])
        queue_start = start_header[/t=([\d\.]+)/, 1].to_f
        Statue.report_duration 'request.queue', (Time.now.to_f - queue_start) * 1_000
      end
    end

    def report_response_metrics(env, response, duration)
      metric_name = metric_name(env)
      status, _headers, _body = response

      Statue.report_duration "#{metric_name}.runtime", duration

      Statue.report_increment "#{metric_name}.status-#{status}"
      Statue.report_increment "#{metric_name}.#{status_group(status)}"
    end

    def report_exception(env, _exception)
      Statue.report_increment "#{metric_name(env)}.unhandled-exception"
    end

    def metric_name(env)
      "request.#{env['REQUEST_METHOD']}.#{@path_name.call(env)}"
    end

    # success: ok (2XX)
    # failure: client error (4xx)
    # error: server error (5xx)
    # unmodified: (304)
    # redirect: (3XX)
    def status_group(status)
      case status.to_i
      when 100..299
        'success'
      when 304
        'unmodified'
      when 300..399
        'redirect'
      when 400..499
        'failure'
      when 500..599
        'error'
      else
        'invalid-status'
      end
    end

  end
end
