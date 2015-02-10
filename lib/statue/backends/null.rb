module Statue
  class NullBackend

    def collect_metric(metric)
    end
    alias :<< :collect_metric

  end
end
