module EnvHelper
  # ブロックの間だけ環境変数を変え、終わったら元に戻す。nil を渡すと消す
  def with_env(vars)
    original = vars.keys.to_h { |name| [ name, ENV[name] ] }
    vars.each { |name, value| ENV[name] = value }
    yield
  ensure
    original&.each { |name, value| ENV[name] = value }
  end

  # Rails.env を差し替える。本番の設定での振る舞いを確かめるため
  def stub_rails_env(name)
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new(name))
  end
end

RSpec.configure do |config|
  config.include EnvHelper

  # 手元のシェルで OUTBOUND_ALLOWED_HOSTS を設定していても、テストの結果が変わらないようにする
  config.around do |example|
    with_env("OUTBOUND_ALLOWED_HOSTS" => nil) { example.run }
  end
end
