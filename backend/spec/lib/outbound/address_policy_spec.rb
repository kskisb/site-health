require "rails_helper"

RSpec.describe Outbound::AddressPolicy do
  {
    "ループバック" => %w[127.0.0.1 127.255.255.254 ::1],
    "プライベート" => %w[10.0.0.1 172.16.0.1 172.31.255.255 192.168.1.1 fc00::1 fd12:3456::1],
    "リンクローカル（クラウドの管理用を含む）" => %w[169.254.169.254 169.254.0.1 fe80::1],
    "CGNAT" => %w[100.64.0.1 100.127.255.255],
    "0.0.0.0/8 と未指定" => %w[0.0.0.0 0.1.2.3 ::],
    "マルチキャスト" => %w[224.0.0.1 239.255.255.255 ff02::1],
    "予約済み・ブロードキャスト" => %w[240.0.0.1 255.255.255.255],
    "文書用・性能試験用・IETFの予約" => %w[192.0.2.1 198.51.100.1 203.0.113.1 198.18.0.1 192.0.0.1 2001:db8::1 3fff::1],
    "IPv4を埋め込んだIPv6" => %w[::ffff:127.0.0.1 ::ffff:169.254.169.254 ::127.0.0.1 64:ff9b::7f00:1 2002:7f00:1::1 2001:0:4136:e378::1]
  }.each do |kind, addresses|
    it "#{kind}は断る" do
      addresses.each { |address| expect(described_class.allowed?(address)).to be(false), address }
    end
  end

  it "公開されたアドレスは通す" do
    %w[93.184.215.14 1.1.1.1 8.8.8.8 172.32.0.1 100.128.0.1 2606:2800:21f:cb07:6820:80da:af6b:8b2c 2a00:1450:4001::1].each do |address|
      expect(described_class.allowed?(address)).to be(true), address
    end
  end

  it "IPAddr もそのまま受け取る" do
    expect(described_class.allowed?(IPAddr.new("127.0.0.1"))).to be(false)
  end
end
