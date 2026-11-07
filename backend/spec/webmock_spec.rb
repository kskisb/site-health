require "rails_helper"

RSpec.describe "テスト中の外への通信" do
  it "stub していないリクエストは止まる" do
    expect { Net::HTTP.get(URI("https://example.com/")) }
      .to raise_error(WebMock::NetConnectNotAllowedError)
  end

  it "stub_request で決めた応答が返る" do
    stub_request(:get, "https://example.com/").to_return(status: 200, body: "ok")

    expect(Net::HTTP.get(URI("https://example.com/"))).to eq("ok")
  end
end
