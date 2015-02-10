require 'socket'

module Statue
  class UDPBackend
    attr_reader :address

    def initialize(host = nil, port = nil)
      @address = Addrinfo.udp(host || "127.0.0.1", port || 8125)
    end

    def collect_metric(metric)
      if metric.sample_rate == 1 || rand < metric.sample_rate
        send_to_socket metric.to_s
      end
    end
    alias :<< :collect_metric

    private

    def socket
      @socket ||= address.connect
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
