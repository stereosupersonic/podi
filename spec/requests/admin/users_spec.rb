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

    describe "PATCH /admin/users/:id" do
      it "keeps your own admin flag" do
        patch "/admin/users/#{admin.id}", params: { user: { admin: "0" } }

        expect(admin.reload).to be_admin
      end
    end
  end
end
