module Outbound
  # 手元とテストでだけ、環境変数 OUTBOUND_ALLOWED_HOSTS（カンマ区切り）に入れたホストを通す。
  # 手元で立てたサーバーを点検して確かめるため。許可したホストは、ホスト名の形・ポート・
  # IPアドレスの確認を飛ばす。本番（development と test 以外）では環境変数を読まない
  module Allowlist
    ENV_NAME = "OUTBOUND_ALLOWED_HOSTS".freeze

    def self.include?(host)
      hosts.include?(host.to_s.downcase)
    end

    def self.hosts
      return [] unless Rails.env.local?

      ENV.fetch(ENV_NAME, "").split(",").map { |host| host.strip.downcase }.reject(&:empty?)
    end
  end
end
