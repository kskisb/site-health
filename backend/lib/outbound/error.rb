module Outbound
  # 外へのリクエストを断ったとき・つなげなかったときの例外。
  # 理由は code（Symbol）で持ち、画面はこのコードを日本語に直して出す
  class Error < StandardError
    CODES = %i[
      invalid_url
      invalid_host
      forbidden_scheme
      forbidden_port
      credentials_in_url
      ip_address_host
      not_found
      dns_timeout
      private_address
      connect_timeout
      connection_refused
      connection_failed
    ].freeze

    attr_reader :code

    def initialize(code, detail = nil)
      raise ArgumentError, "unknown code: #{code.inspect}" unless CODES.include?(code)

      @code = code
      super(detail ? "#{code}: #{detail}" : code.to_s)
    end
  end
end
