# テスト中は本物のDNSを引かない。WebMock は HTTP しか止めないため、ここで名前解決も止める。
# 名前解決を使うテストは stub_dns で答えを差し替える（hosts ファイルの localhost は引ける）
RSpec.configure do |config|
  config.before do
    allow_any_instance_of(Resolv::DNS).to receive(:each_resource)
      .and_raise("テスト中に本物のDNSを引こうとした。stub_dns で答えを差し替える")
  end
end
