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

    context "with a cache that counts" do
      let(:counting_store) { ActiveSupport::Cache::MemoryStore.new }

      # rate_limit holds on to the store Rails.cache returned when the controller class loaded (the
      # :null_store in test), so stubbing Rails.cache would not reach it. That store is still the
      # object Rails.cache returns, so its increment is routed to a store that counts.
      before do
        allow(Rails.cache).to receive(:increment) { |*args, **options| counting_store.increment(*args, **options) }
      end

      it "allows 10 attempts within 3 minutes" do
        10.times { post "/login", params: { email: user.email, password: "wrong" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects the 11th attempt within 3 minutes", :aggregate_failures do
        10.times { post "/login", params: { email: user.email, password: "wrong" } }

        post "/login", params: { email: user.email, password: password }

        expect(response).to have_http_status(:too_many_requests)
        expect(response.body).to include("Too many sign-in attempts. Please try again in a few minutes.")
        expect(session[:user_id]).to be_nil
      end

      it "allows attempts again after 3 minutes" do
        11.times { post "/login", params: { email: user.email, password: "wrong" } }

        travel 3.minutes + 1.second do
          post "/login", params: { email: user.email, password: password }

          expect(response).to redirect_to("/admin/statistics")
        end
      end

      it "counts attempts per IP" do
        11.times { post "/login", params: { email: user.email, password: "wrong" } }

        post "/login", params: { email: user.email, password: password }, env: { "REMOTE_ADDR" => "203.0.113.9" }

        expect(response).to redirect_to("/admin/statistics")
      end
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
