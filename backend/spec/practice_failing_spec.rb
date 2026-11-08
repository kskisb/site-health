require "rails_helper"

# 練習のプルリクエスト（SH-4）：わざと落とすテスト。マージできないことを確かめたら閉じる
RSpec.describe "練習" do
  it "わざと落ちる" do
    expect(1 + 1).to eq(3)
  end
end
