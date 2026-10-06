require "rails_helper"

RSpec.describe "sessions", type: :request do
  let(:user) { create(:user, :admin) }
  let(:password) { LoginHelpers::DEFAULT_TEST_PASSWORD }

  before { create(:setting) }

  describe "POST /login" do
    it "signs in with the right password", :aggregate_failures do
      post "/login", params: { email: user.email, password: password }

      expect(response).to redirect_to("/admin/statistics")
      expect(session[:user_id]).to eq(user.id)
    end

    it "re-renders the form with the wrong password", :aggregate_failures do
      post "/login", params: { email: user.email, password: "wrong" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Invalid email or password")
      expect(session[:user_id]).to be_nil
    end

    it "starts a fresh session", :aggregate_failures do
      get "/admin/statistics"
      session_id_before_login = session.id.to_s

      post "/login", params: { email: user.email, password: password }

      expect(session.id.to_s).not_to eq(session_id_before_login)
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe "DELETE /logout" do
    before { post "/login", params: { email: user.email, password: password } }

    it "clears the whole session", :aggregate_failures do
      session_id_before_logout = session.id.to_s

      delete "/logout"

      expect(response).to redirect_to("/")
      expect(flash[:notice]).to eq("Signed out successfully")
      expect(session.id.to_s).not_to eq(session_id_before_logout)
      expect(session.to_hash).not_to have_key("user_id")
    end
  end
end
