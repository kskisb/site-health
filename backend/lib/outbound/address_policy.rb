require "ipaddr"

module Outbound
  # 点検で取りに行ってよいIPアドレスか。インターネットに公開されたユニキャストのアドレスだけを通す
  module AddressPolicy
    # IPv4 のうち、インターネットから届かないもの（IANA の特別な用途のアドレスから）
    BLOCKED_IPV4 = %w[
      0.0.0.0/8
      10.0.0.0/8
      100.64.0.0/10
      127.0.0.0/8
      169.254.0.0/16
      172.16.0.0/12
      192.0.0.0/24
      192.0.2.0/24
      192.88.99.0/24
      192.168.0.0/16
      198.18.0.0/15
      198.51.100.0/24
      203.0.113.0/24
      224.0.0.0/4
      240.0.0.0/4
    ].map { |cidr| IPAddr.new(cidr) }.freeze
    # 0.0.0.0/8：この端末自身 / 10/8・172.16/12・192.168/16：プライベート / 100.64/10：CGNAT /
    # 127/8：ループバック / 169.254/16：リンクローカル（169.254.169.254 のクラウドの管理用も入る） /
    # 192.0.0/24：IETFの予約 / 192.0.2/24・198.51.100/24・203.0.113/24：文書用 /
    # 192.88.99/24：6to4の中継 / 198.18/15：性能試験用 / 224/4：マルチキャスト / 240/4：予約済み（255.255.255.255 も入る）

    # IPv6 は、グローバルユニキャスト（2000::/3）だけを通す。これで ::1（ループバック）、
    # fc00::/7（プライベート）、fe80::/10（リンクローカル）、ff00::/8（マルチキャスト）、
    # ::ffff:0:0/96 や 64:ff9b::/96（IPv4を埋め込んだもの）などが外れる
    GLOBAL_UNICAST_IPV6 = IPAddr.new("2000::/3")

    # 2000::/3 の中でも断るもの
    BLOCKED_IPV6 = %w[
      2001::/23
      2001:db8::/32
      2002::/16
      3fff::/20
    ].map { |cidr| IPAddr.new(cidr) }.freeze
    # 2001::/23：IETFの予約（IPv4を埋め込む Teredo の 2001::/32 も入る） / 2001:db8::/32・3fff::/20：文書用 /
    # 2002::/16：6to4（IPv4を埋め込む）

    def self.allowed?(address)
      ip = address.is_a?(IPAddr) ? address : IPAddr.new(address.to_s)

      if ip.ipv4?
        BLOCKED_IPV4.none? { |range| range.include?(ip) }
      else
        GLOBAL_UNICAST_IPV6.include?(ip) && BLOCKED_IPV6.none? { |range| range.include?(ip) }
      end
    end
  end
end
