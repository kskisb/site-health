require "rails_helper"

# SH-5 の「テストで確かめるURL」の表。URLを読み取って名前を解決するところまで通し、断るか通るかを見る
RSpec.describe "外へのリクエストの宛先の確認（SSRF対策）" do
  def check(url)
    target = Outbound::Target.parse(url)
    Outbound::Resolver.resolve(target.host)
  end

  before do
    stub_dns(
      "example.com" => %w[93.184.215.14 2606:2800:21f:cb07:6820:80da:af6b:8b2c],
      "rebind.example.com" => %w[127.0.0.1]
    )
  end

  {
    "http://localhost/" => :invalid_host,
    "http://127.0.0.1/" => :ip_address_host,
    "http://[::1]/" => :ip_address_host,
    "http://169.254.169.254/latest/meta-data/" => :ip_address_host,
    "http://10.0.0.1/" => :ip_address_host,
    "http://192.168.1.1/" => :ip_address_host,
    "http://2130706433/" => :ip_address_host,
    "ftp://example.com/" => :forbidden_scheme,
    "http://example.com:22/" => :forbidden_port,
    "http://user:pass@example.com/" => :credentials_in_url,
    "http://rebind.example.com/" => :private_address
  }.each do |url, code|
    it "#{url} は断る（#{code}）" do
      expect { check(url) }.to raise_error(Outbound::Error) { |error| expect(error.code).to eq(code) }
    end
  end

  it "https://example.com/ は通る" do
    expect(check("https://example.com/").map(&:to_s))
      .to eq(%w[93.184.215.14 2606:2800:21f:cb07:6820:80da:af6b:8b2c])
  end
end
