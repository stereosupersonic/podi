# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  last_used_at :datetime
#  name         :string           not null
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_token_digest  (token_digest) UNIQUE
#  index_api_tokens_on_user_id       (user_id)
#
# Foreign Keys
#
#  api_tokens_user_id_fk  (user_id => users.id) ON DELETE => cascade
#
require "rails_helper"

RSpec.describe ApiToken, type: :model do
  let(:admin) { create(:user, :admin) }

  it "has a valid factory" do
    api_token = build(:api_token)

    expect(api_token).to be_valid
    assert api_token.save!
  end

  describe ".issue" do
    it "creates a token and exposes the plaintext once", :aggregate_failures do
      token = described_class.issue(user: admin, name: "n8n")

      expect(token).to be_persisted
      expect(token.plaintext_token).to start_with("podi_")
      expect(token.token_digest).to eq(Digest::SHA256.hexdigest(token.plaintext_token))
      expect(described_class.find(token.id).plaintext_token).to be_nil
    end

    context "without a name" do
      it "is not persisted", :aggregate_failures do
        token = described_class.issue(user: admin, name: "")

        expect(token).not_to be_persisted
        expect(token.errors[:name]).to include("can't be blank")
      end
    end
  end

  describe ".authenticate" do
    let!(:token) { described_class.issue(user: admin, name: "n8n") }

    it "finds the token for a valid plaintext" do
      expect(described_class.authenticate(token.plaintext_token)).to eq(token)
    end

    it "returns nil for an unknown token" do
      expect(described_class.authenticate("podi_unknown")).to be_nil
    end

    it "returns nil for a blank token" do
      expect(described_class.authenticate(nil)).to be_nil
    end

    context "when the user is no longer an admin" do
      it "returns nil" do
        admin.update!(admin: false)

        expect(described_class.authenticate(token.plaintext_token)).to be_nil
      end
    end
  end

  describe "#record_usage" do
    let(:token) { described_class.issue(user: admin, name: "n8n") }

    it "stores when the token was used" do
      freeze_time do
        token.record_usage

        expect(token.reload.last_used_at).to eq(Time.current)
      end
    end

    it "writes at most once a minute" do
      token.record_usage
      first_use = token.reload.last_used_at

      travel 30.seconds do
        token.record_usage
        expect(token.reload.last_used_at).to eq(first_use)
      end
    end
  end

  it "is destroyed with its user" do
    described_class.issue(user: admin, name: "n8n")

    expect { admin.destroy }.to change(described_class, :count).by(-1)
  end
end
