require "ipaddr"
require "resolv"
require "timeout"

module Outbound
  # 名前を解決し、点検してよいIPアドレスを返す。1つでも内側のアドレスが混じっていたら断る
  module Resolver
    TIMEOUT = 2 # 秒。A と AAAA を引き終えるまでの合計

    # IPv4 を先、IPv6 を後に並べた IPAddr の配列を返す
    def self.resolve(host)
      host = host.to_s.downcase
      return resolve_allowed(host) if Allowlist.include?(host)

      addresses = lookup(host)
      raise Error.new(:not_found, host) if addresses.empty?

      blocked = addresses.reject { |address| AddressPolicy.allowed?(address) }
      raise Error.new(:private_address, "#{host} -> #{blocked.join(", ")}") if blocked.any?

      addresses
    end

    def self.lookup(host)
      # 末尾に . を付けて、検索ドメイン（resolv.conf の search）を付け足して引かないようにする
      name = Resolv::DNS::Name.create("#{host}.")

      Timeout.timeout(TIMEOUT) do
        Resolv::DNS.open do |dns|
          dns.timeouts = TIMEOUT
          v4 = dns.getresources(name, Resolv::DNS::Resource::IN::A)
          v6 = dns.getresources(name, Resolv::DNS::Resource::IN::AAAA)
          (v4 + v6).map { |resource| IPAddr.new(resource.address.to_s) }.uniq
        end
      end
    rescue Timeout::Error
      raise Error.new(:dns_timeout, host)
    end
    private_class_method :lookup

    # 許可リストのホスト（手元とテストだけ）。hosts ファイルも見て、IPアドレスの確認はしない
    def self.resolve_allowed(host)
      addresses = Resolv.getaddresses(host).map { |address| IPAddr.new(address) }.uniq
      raise Error.new(:not_found, host) if addresses.empty?

      addresses.sort_by { |address| address.ipv4? ? 0 : 1 }
    end
    private_class_method :resolve_allowed
  end
end
