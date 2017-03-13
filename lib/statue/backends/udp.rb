require 'socket'

module Statue
  class UDPBackend
    attr_reader :host, :port

    def self.from_uri(uri)
      uri = URI(uri)
      new(host: uri.host, port: uri.port)
    end

    def initialize(host:, port:)
      @host = host
      @port = port
    end

    def collect_metric(metric)
      if metric.sample_rate == 1 || rand < metric.sample_rate
        send_to_socket metric.to_s
      end
    end
    alias :<< :collect_metric

    private

    def socket
      Thread.current[:statue_socket] ||= begin
        socket = UDPSocket.new(Addrinfo.ip(host).afamily)
        socket.connect(host, port)
        socket
      end
    end

    def send_to_socket(message)
      Statue.debug(message)
      socket.send(message, 0)
    rescue => e
      Statue.error("#{e.class} #{e}")
      nil
    end

  end
end
