require "rails_helper"

RSpec.describe "admin episodes", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    create(:setting)
    post "/login", params: { email: admin.email, password: LoginHelpers::DEFAULT_TEST_PASSWORD }
  end

  describe "POST /admin/episodes" do
    context "with invalid attributes" do
      it "re-renders the form as unprocessable content" do
        post "/admin/episodes", params: { episode: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /admin/episodes/:id" do
    context "with invalid attributes" do
      it "re-renders the form as unprocessable content" do
        episode = create(:episode)

        patch "/admin/episodes/#{episode.slug}", params: { episode: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
