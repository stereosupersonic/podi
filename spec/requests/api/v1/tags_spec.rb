require "rails_helper"

RSpec.describe "API v1 tags", type: :request do
  let!(:setting) { create(:setting) }
  let(:admin) { create(:user, :admin) }
  let(:token) { ApiToken.issue(user: admin, name: "agent") }

  context "with a valid token" do
    it "lists every tag in use", :aggregate_failures do
      create(:episode, tags: %w[Musik Interview])

      get "/api/v1/tags", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("tags" => %w[Interview Musik])
    end
  end

  context "without a token" do
    it "answers unauthorized" do
      get "/api/v1/tags"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
