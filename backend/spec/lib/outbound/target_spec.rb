require "rails_helper"

RSpec.describe Outbound::Target do
  def parse(url)
    described_class.parse(url)
  end

  def expect_rejected(url, code)
    expect { parse(url) }.to raise_error(Outbound::Error) { |error| expect(error.code).to eq(code) }
  end

  describe "通るURL" do
    it "https のURLを読み取る" do
      target = parse("https://example.com/path?q=1#section")

      expect(target).to have_attributes(scheme: "https", host: "example.com", port: 443, request_uri: "/path?q=1")
      expect(target).to be_https
    end

    it "http はポート80、明示した :443 も通る" do
      expect(parse("http://example.com").port).to eq(80)
      expect(parse("https://example.com:443/").port).to eq(443)
    end

    it "大文字は小文字に直し、末尾の . と前後の空白は取る" do
      expect(parse("  HTTPS://Example.COM./  ").host).to eq("example.com")
    end

    it "日本語ドメインは punycode に直す" do
      expect(parse("https://日本語.jp/").host).to eq("xn--wgv71a119e.jp")
    end
  end

  describe "URLの形" do
    it "読み取れないURLは断る" do
      expect_rejected("http://", :invalid_url)
      expect_rejected("http://exa mple.com/", :invalid_url)
      expect_rejected("example.com", :invalid_url)
      expect_rejected("", :invalid_url)
    end

    it "長すぎるURLは断る" do
      expect_rejected("https://example.com/#{"a" * 2048}", :invalid_url)
    end

    it "http と https 以外は断る" do
      expect_rejected("ftp://example.com/", :forbidden_scheme)
      expect_rejected("file:///etc/passwd", :forbidden_scheme)
      expect_rejected("gopher://example.com/", :forbidden_scheme)
    end

    it "ポートは 80 と 443 だけ" do
      expect_rejected("http://example.com:22/", :forbidden_port)
      expect_rejected("https://example.com:8443/", :forbidden_port)
      expect_rejected("http://example.com:65536/", :forbidden_port)
    end

    it ":0 と : は、addressable の読み方どおり既定のポートとして扱う（つなぐ先も同じポート）" do
      expect(parse("http://example.com:0/").port).to eq(80)
      expect(parse("https://example.com:/").port).to eq(443)
    end

    it "user:pass@ の付いたURLは断る" do
      expect_rejected("http://user:pass@example.com/", :credentials_in_url)
      expect_rejected("http://user@example.com/", :credentials_in_url)
    end
  end

  describe "ホスト名" do
    it "IPアドレスの直書きは断る（10進数・16進数・省略形も）" do
      %w[
        http://127.0.0.1/ http://[::1]/ http://[::ffff:127.0.0.1]/ http://169.254.169.254/
        http://2130706433/ http://0x7f000001/ http://127.1/ http://0177.0.0.1/ http://93.184.215.14/
      ].each { |url| expect_rejected(url, :ip_address_host) }
    end

    it "ドメイン名の形でないものは断る" do
      expect_rejected("http://localhost/", :invalid_host)
      expect_rejected("http://intranet/", :invalid_host)
      expect_rejected("http://exa_mple.com/", :invalid_host)
      expect_rejected("http://-example.com/", :invalid_host)
      expect_rejected("http://#{"a" * 64}.com/", :invalid_host)
    end
  end

  describe "許可リスト（手元とテストだけ）" do
    it "許可したホストは、ホスト名の形とポートの確認を飛ばす" do
      with_env("OUTBOUND_ALLOWED_HOSTS" => "localhost, 127.0.0.1") do
        expect(parse("http://localhost:3001/").port).to eq(3001)
        expect(parse("http://127.0.0.1:8080/").host).to eq("127.0.0.1")
      end
    end

    it "許可していても、スキームと user:pass@ の確認はする" do
      with_env("OUTBOUND_ALLOWED_HOSTS" => "localhost") do
        expect_rejected("ftp://localhost/", :forbidden_scheme)
        expect_rejected("http://user:pass@localhost/", :credentials_in_url)
      end
    end

    it "本番の設定では、許可リストが効かない" do
      stub_rails_env("production")

      with_env("OUTBOUND_ALLOWED_HOSTS" => "localhost,127.0.0.1") do
        expect_rejected("http://localhost:3001/", :invalid_host)
        expect_rejected("http://127.0.0.1/", :ip_address_host)
      end
    end
  end
end
