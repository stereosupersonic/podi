require "rails_helper"

RSpec.describe "admin api tokens", type: :request do
  let(:admin) { create(:user, :admin) }

  before { post "/login", params: { email: admin.email, password: LoginHelpers::DEFAULT_TEST_PASSWORD } }

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
