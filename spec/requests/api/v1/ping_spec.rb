require "rails_helper"

RSpec.describe "API v1 ping", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:token) { ApiToken.issue(user: admin, name: "agent") }

  context "with a valid token" do
    it "confirms the token and says whose it is", :aggregate_failures do
      get "/api/v1/ping", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "status" => "ok",
        "user" => { "email" => admin.email },
        "token" => { "name" => "agent" }
      )
    end

    it "records that the token was used" do
      get "/api/v1/ping", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }

      expect(token.reload.last_used_at).to be_present
    end
  end

  context "without a token" do
    it "answers unauthorized with an error message", :aggregate_failures do
      get "/api/v1/ping"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "unauthorized", "message" => "Missing or invalid API token")
    end
  end

  context "with an unknown token" do
    it "answers unauthorized" do
      get "/api/v1/ping", headers: { "Authorization" => "Bearer podi_wrong" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when the token's user is no longer an admin" do
    it "answers unauthorized" do
      plaintext = token.plaintext_token
      admin.update!(admin: false)

      get "/api/v1/ping", headers: { "Authorization" => "Bearer #{plaintext}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
