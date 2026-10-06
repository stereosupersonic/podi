require "rails_helper"

RSpec.describe "admin users", type: :request do
  let(:admin) { create(:user, :admin) }

  before { create(:setting) }

  context "when logged in as a non-admin" do
    let(:user) { create(:user) }

    before { post "/login", params: { email: user.email, password: LoginHelpers::DEFAULT_TEST_PASSWORD } }

    it "denies access", :aggregate_failures do
      get "/admin/users"

      expect(response).to redirect_to("/")
      expect(flash[:alert]).to eq("Access Denied")
    end
  end

  context "when logged in as admin" do
    before { post "/login", params: { email: admin.email, password: LoginHelpers::DEFAULT_TEST_PASSWORD } }

    describe "DELETE /admin/users/:id" do
      it "keeps the logged-in admin", :aggregate_failures do
        delete "/admin/users/#{admin.id}"

        expect(response).to redirect_to("/admin/users")
        expect(flash[:alert]).to eq("You cannot delete yourself.")
        expect(User.exists?(admin.id)).to be(true)
      end
    end

    describe "GET /admin/users/:id/edit" do
      it "sends you to your account page for yourself" do
        get "/admin/users/#{admin.id}/edit"

        expect(response).to redirect_to("/account/edit")
      end

      it "edits another user" do
        user = create(:user)

        get "/admin/users/#{user.id}/edit"

        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /admin/users/:id" do
      it "does not change your own email and password", :aggregate_failures do
        patch "/admin/users/#{admin.id}",
              params: { user: { email: "hijacked@test.com", password: "Hijacked123!",
                                password_confirmation: "Hijacked123!" } }

        expect(response).to redirect_to("/account/edit")
        expect(admin.reload.email).not_to eq("hijacked@test.com")
        expect(admin.authenticate(LoginHelpers::DEFAULT_TEST_PASSWORD)).to eq(admin)
      end

      it "updates another user", :aggregate_failures do
        user = create(:user)

        patch "/admin/users/#{user.id}", params: { user: { email: "cohost@test.com", admin: "1" } }

        expect(response).to redirect_to("/admin/users")
        expect(user.reload.email).to eq("cohost@test.com")
        expect(user).to be_admin
      end
    end
  end
end
