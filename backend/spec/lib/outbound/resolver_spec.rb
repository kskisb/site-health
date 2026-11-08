require "rails_helper"

RSpec.describe Outbound::Resolver do
  def expect_rejected(host, code)
    expect { described_class.resolve(host) }.to raise_error(Outbound::Error) { |error| expect(error.code).to eq(code) }
  end

  it "A と AAAA を引き、IPv4 を先に並べて返す" do
    stub_dns("example.com" => %w[2606:2800:21f:cb07:6820:80da:af6b:8b2c 93.184.215.14])

    expect(described_class.resolve("example.com").map(&:to_s))
      .to eq(%w[93.184.215.14 2606:2800:21f:cb07:6820:80da:af6b:8b2c])
  end

  it "末尾に . を付けた名前で引き、待ち時間を2秒にする" do
    dns = stub_dns("example.com" => %w[93.184.215.14])

    described_class.resolve("example.com")

    expect(dns).to have_received(:timeouts=).with(2)
    expect(dns).to have_received(:getresources).with(satisfy(&:absolute?), anything).twice
  end

  it "答えがないときは not_found" do
    stub_dns({})

    expect_rejected("nxdomain.example.com", :not_found)
  end

  it "内側のアドレスが返ったら断る" do
    stub_dns("rebind.example.com" => %w[127.0.0.1], "metadata.example.com" => %w[169.254.169.254])

    expect_rejected("rebind.example.com", :private_address)
    expect_rejected("metadata.example.com", :private_address)
  end

  it "公開されたアドレスに1つでも内側のアドレスが混じっていたら断る" do
    stub_dns("mixed.example.com" => %w[93.184.215.14 10.0.0.1])

    expect_rejected("mixed.example.com", :private_address)
  end

  it "AAAA に IPv4 を埋め込んだアドレスが返ったら断る" do
    stub_dns("mapped.example.com" => %w[::ffff:127.0.0.1])

    expect_rejected("mapped.example.com", :private_address)
  end

  it "2秒以内に答えが返らないときは dns_timeout" do
    stub_const("Outbound::Resolver::TIMEOUT", 0.05)
    dns = stub_dns({})
    allow(dns).to receive(:getresources) { sleep 1 }

    expect_rejected("slow.example.com", :dns_timeout)
  end

  describe "許可リスト（手元とテストだけ）" do
    it "許可したホストは hosts ファイルも見て、内側のアドレスでも返す" do
      with_env("OUTBOUND_ALLOWED_HOSTS" => "localhost") do
        expect(described_class.resolve("localhost").first.to_s).to eq("127.0.0.1")
      end
    end

    it "本番の設定では、許可リストが効かない" do
      stub_rails_env("production")
      stub_dns("localhost" => %w[127.0.0.1])

      with_env("OUTBOUND_ALLOWED_HOSTS" => "localhost") do
        expect_rejected("localhost", :private_address)
      end
    end
  end
end
