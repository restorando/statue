module Statue
  class LoggerBackend < Struct.new(:logger)

    def collect_metric(metric)
      logger.info("Statue") { metric.to_s }
    end
    alias :<< :collect_metric

  end
end
