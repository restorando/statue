module Statue
  autoload :LoggerBackend,  "statue/backends/logger"
  autoload :CaptureBackend, "statue/backends/capture"
  autoload :NullBackend,    "statue/backends/null"
  autoload :UDPBackend,     "statue/backends/udp"
end
