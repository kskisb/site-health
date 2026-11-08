require "socket"

module Outbound
  # 確かめたIPアドレスへ、そのままTCPでつなぐ。つなぐ直前に名前をもう一度引かない。
  # 引き直すと、1回目は安全なIP、2回目は内側のIPを返す手口（DNSリバインディング）に負けるため。
  # SSLの点検（SH-6）とHTTP（SH-18）は、この上に作る
  module Connection
    CONNECT_TIMEOUT = 5 # 秒。1つのIPアドレスにつき
    MAX_ATTEMPTS = 2 # 1つ目のIPアドレスにつながらないとき、2つ目までは試す

    # ブロックを渡すと、終わったあとにソケットを閉じる。渡さないときはソケットを返す
    def self.open(target)
      socket = connect(Resolver.resolve(target.host), target.port)
      return socket unless block_given?

      begin
        yield socket
      ensure
        socket.close
      end
    end

    def self.connect(addresses, port)
      error = nil

      addresses.first(MAX_ATTEMPTS).each do |address|
        return Socket.tcp(address.to_s, port, connect_timeout: CONNECT_TIMEOUT)
      rescue IO::TimeoutError, Errno::ETIMEDOUT
        error = Error.new(:connect_timeout, "#{address}:#{port}")
      rescue Errno::ECONNREFUSED
        error = Error.new(:connection_refused, "#{address}:#{port}")
      rescue SystemCallError, SocketError => e
        error = Error.new(:connection_failed, "#{address}:#{port} #{e.class}")
      end

      raise error
    end
    private_class_method :connect
  end
end
