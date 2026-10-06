require "rails_helper"

RSpec.describe "admin api tokens", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    create(:setting)
    post "/login", params: { email: admin.email, password: LoginHelpers::DEFAULT_TEST_PASSWORD }
  end

  describe "POST /admin/api_tokens" do
    it "keeps the page with the plaintext token out of every cache", :aggregate_failures do
      post "/admin/api_tokens", params: { api_token: { name: "n8n" } }

      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.body).to include('<meta name="turbo-cache-control" content="no-cache">')
    end
  end

  describe "DELETE /admin/api_tokens/:id" do
    context "with another admin's token" do
      it "responds not found and keeps the token", :aggregate_failures do
        token = create(:api_token)

        delete "/admin/api_tokens/#{token.id}"

        expect(response).to have_http_status(:not_found)
        expect(ApiToken.exists?(token.id)).to be(true)
      end
    end
  end
end
