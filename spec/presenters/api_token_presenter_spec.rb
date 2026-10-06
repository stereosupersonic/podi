require "rails_helper"

RSpec.describe ApiTokenPresenter, type: :model do
  let(:api_token) { create(:api_token, created_at: Time.zone.parse("2026-10-06 09:30")) }
  let(:presenter) { described_class.new(api_token) }

  it "formats the created_at" do
    expect(presenter.created_at).to eq("06.10.2026 09:30")
  end

  describe "#last_used" do
    context "when the token was used" do
      before { api_token.update!(last_used_at: Time.zone.parse("2026-10-06 14:05")) }

      it "returns the formatted datetime" do
        expect(presenter.last_used).to eq("06.10.2026 14:05")
      end
    end

    context "when the token was never used" do
      it "returns Never" do
        expect(presenter.last_used).to eq("Never")
      end
    end
  end
end
