module Statue
  class CaptureBackend
    attr_reader :captures

    def initialize
      @captures = []
    end

    def collect_metric(metric)
      @captures << metric
    end
    alias :<< :collect_metric

  end
end
