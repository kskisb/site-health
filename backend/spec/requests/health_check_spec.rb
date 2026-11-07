require "rails_helper"

RSpec.describe "ヘルスチェック", type: :request do
  it "GET /up は200を返す" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
