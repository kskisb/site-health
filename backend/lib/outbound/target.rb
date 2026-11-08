require "addressable/uri"
require "ipaddr"

module Outbound
  # 利用者が入れたURLを読み取り、点検してよい形かを確かめる。名前解決はしない（Resolver の役目）
  class Target
    SCHEMES = %w[http https].freeze
    PORTS = [ 80, 443 ].freeze
    MAX_URL_LENGTH = 2048
    MAX_HOST_LENGTH = 253
    LABEL = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/
    # 127.1 や 0x7f000001 のように、数字で書いたIPv4。正しいドメインの最後のラベルが数字だけになることはない
    NUMERIC_LABEL = /\A(?:[0-9]+|0x[0-9a-f]*)\z/

    attr_reader :scheme, :host, :port, :request_uri

    def self.parse(url)
      url = url.to_s.strip
      raise Error.new(:invalid_url, "too long") if url.length > MAX_URL_LENGTH

      uri = Addressable::URI.parse(url)
      scheme = uri.normalized_scheme
      raise Error.new(:invalid_url, "missing scheme") if scheme.nil?
      raise Error.new(:forbidden_scheme, scheme) unless SCHEMES.include?(scheme)
      raise Error.new(:invalid_url, "missing host") if uri.normalized_host.blank?
      raise Error.new(:credentials_in_url) if uri.userinfo.present?

      # 日本語ドメインは punycode に、大文字は小文字に直り、末尾の . は取れる
      host = uri.normalized_host.delete_prefix("[").delete_suffix("]")
      # :0 や : は、addressable が「指定なし」として読み、既定のポートになる。
      # ここで自前に読み直さないのは、確かめるときとつなぐときでURLの読み方がずれないようにするため
      port = uri.inferred_port

      unless Allowlist.include?(host)
        check_host!(host)
        raise Error.new(:forbidden_port, port.to_s) unless PORTS.include?(port)
      end

      new(scheme:, host:, port:, request_uri: uri.normalize.request_uri.presence || "/")
    rescue Addressable::URI::InvalidURIError => e
      raise Error.new(:invalid_url, e.message)
    end

    def self.check_host!(host)
      raise Error.new(:ip_address_host, host) if ip_address?(host)
      raise Error.new(:invalid_host, host) unless domain_name?(host)
    end
    private_class_method :check_host!

    def self.ip_address?(host)
      IPAddr.new(host)
      true
    rescue IPAddr::InvalidAddressError
      NUMERIC_LABEL.match?(host.split(".").last.to_s)
    end
    private_class_method :ip_address?

    # ラベルが2つ以上ある、英数字とハイフンだけのドメイン名か。localhost のような1語の名前は通さない
    def self.domain_name?(host)
      labels = host.split(".", -1)
      host.length <= MAX_HOST_LENGTH && labels.size >= 2 && labels.all? { |label| LABEL.match?(label) }
    end
    private_class_method :domain_name?

    def initialize(scheme:, host:, port:, request_uri:)
      @scheme = scheme
      @host = host
      @port = port
      @request_uri = request_uri
      freeze
    end

    def https?
      scheme == "https"
    end
  end
end
