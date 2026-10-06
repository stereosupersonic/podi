require "rails_helper"

RSpec.describe "admin settings", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    create(:setting)
    post "/login", params: { email: admin.email, password: LoginHelpers::DEFAULT_TEST_PASSWORD }
  end

  describe "PATCH /admin/setting" do
    context "with invalid attributes" do
      it "re-renders the form as unprocessable content" do
        patch "/admin/setting", params: { setting: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
