require "rails_helper"

RSpec.describe Outbound::Connection do
  let(:target) { Outbound::Target.parse("https://example.com/") }
  let(:socket) { instance_double(Socket, close: nil) }

  def expect_rejected(code)
    expect { described_class.open(target) }.to raise_error(Outbound::Error) { |error| expect(error.code).to eq(code) }
  end

  it "確かめたIPアドレスへ、名前を引き直さずにつなぐ" do
    allow(Outbound::Resolver).to receive(:resolve).and_return([ IPAddr.new("93.184.215.14") ])
    allow(Socket).to receive(:tcp).and_return(socket)

    expect(described_class.open(target)).to eq(socket)
    expect(Outbound::Resolver).to have_received(:resolve).with("example.com").once
    expect(Socket).to have_received(:tcp).with("93.184.215.14", 443, connect_timeout: 5)
  end

  it "内側のアドレスに解決される名前には、つなぎに行かない" do
    stub_dns("example.com" => %w[127.0.0.1])
    allow(Socket).to receive(:tcp)

    expect_rejected(:private_address)
    expect(Socket).not_to have_received(:tcp)
  end

  it "ブロックを渡すと、終わったあとにソケットを閉じる" do
    allow(Outbound::Resolver).to receive(:resolve).and_return([ IPAddr.new("93.184.215.14") ])
    allow(Socket).to receive(:tcp).and_return(socket)

    expect { |block| described_class.open(target, &block) }.to yield_with_args(socket)
    expect(socket).to have_received(:close)
  end

  it "1つ目のアドレスにつながらないときは、2つ目を試す" do
    allow(Outbound::Resolver).to receive(:resolve)
      .and_return([ IPAddr.new("93.184.215.14"), IPAddr.new("93.184.215.15"), IPAddr.new("93.184.215.16") ])
    allow(Socket).to receive(:tcp).with("93.184.215.14", 443, connect_timeout: 5).and_raise(Errno::ETIMEDOUT)
    allow(Socket).to receive(:tcp).with("93.184.215.15", 443, connect_timeout: 5).and_return(socket)

    expect(described_class.open(target)).to eq(socket)
  end

  it "試すのは2つまで。どれにもつながらなければ、最後の理由を返す" do
    allow(Outbound::Resolver).to receive(:resolve)
      .and_return([ IPAddr.new("93.184.215.14"), IPAddr.new("93.184.215.15"), IPAddr.new("93.184.215.16") ])
    allow(Socket).to receive(:tcp).and_raise(Errno::ECONNREFUSED)

    expect_rejected(:connection_refused)
    expect(Socket).to have_received(:tcp).twice
  end

  it "つながらない理由をコードにする" do
    allow(Outbound::Resolver).to receive(:resolve).and_return([ IPAddr.new("93.184.215.14") ])

    {
      IO::TimeoutError.new => :connect_timeout,
      Errno::ETIMEDOUT.new => :connect_timeout,
      Errno::ECONNREFUSED.new => :connection_refused,
      Errno::EHOSTUNREACH.new => :connection_failed
    }.each do |error, code|
      allow(Socket).to receive(:tcp).and_raise(error)
      expect_rejected(code)
    end
  end

  it "手元で立てたサーバーに、許可リストを通して本当につなぐ" do
    server = TCPServer.new("127.0.0.1", 0)

    with_env("OUTBOUND_ALLOWED_HOSTS" => "localhost") do
      local = Outbound::Target.parse("http://localhost:#{server.addr[1]}/")

      described_class.open(local) do |client|
        expect(client.remote_address.ip_address).to eq("127.0.0.1")
      end
    end
  ensure
    server&.close
  end
end
