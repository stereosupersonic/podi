require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user) }

  describe "POST /login" do
    context "with valid credentials" do
      it "signs in and redirects to admin statistics" do
        post "/login", params: { email: user.email, password: "Test123!" }

        expect(response).to redirect_to(admin_statistics_path)
      end

      it "resets the session to prevent fixation" do
        # Establish a session before login
        get "/login"
        old_session_id = session.id

        post "/login", params: { email: user.email, password: "Test123!" }

        expect(session.id).not_to eq(old_session_id)
      end

      it "sets user_id in session" do
        post "/login", params: { email: user.email, password: "Test123!" }

        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "with invalid credentials" do
      it "re-renders the login form with 422" do
        post "/login", params: { email: user.email, password: "wrong" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not set user_id in session" do
        post "/login", params: { email: user.email, password: "wrong" }

        expect(session[:user_id]).to be_nil
      end
    end
  end

  describe "DELETE /logout" do
    before do
      post "/login", params: { email: user.email, password: "Test123!" }
    end

    it "signs out and redirects to root" do
      delete "/logout"

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil
    end
  end
end
