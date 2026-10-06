require "rails_helper"

RSpec.describe "welcome", type: :request do
  let(:admin) { create(:user, :admin) }

  before { create(:setting) }

  describe "GET /" do
    it "does not answer a page cached while logged in with 304 after logout", :aggregate_failures do
      post "/login", params: { email: admin.email, password: LoginHelpers::DEFAULT_TEST_PASSWORD }
      follow_redirect!
      get "/"
      etag = response.headers["ETag"]
      delete "/logout"
      follow_redirect!

      get "/", headers: { "If-None-Match" => etag }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Administration")
    end
  end
end
