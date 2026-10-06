require "capybara_helper"

describe "API tokens", type: :system do
  let!(:setting) { create(:setting) }
  let(:admin) { create(:user, :admin) }

  context "when logged in as admin" do
    before { login_as admin }

    it "creates a token and shows it once", :aggregate_failures do
      visit "/"
      click_on "API Tokens"
      click_on "Add"

      click_on "Create"
      expect(page).to have_content "Name can't be blank"

      fill_in "Name", with: "n8n publishing"
      click_on "Create"

      plaintext = find_by_id("api-token-plaintext").text
      expect(plaintext).to start_with("podi_")
      expect(ApiToken.authenticate(plaintext).name).to eq("n8n publishing")

      visit "/admin/api_tokens"
      expect(page).to have_content "n8n publishing"
      expect(page).to have_content "Never"
      expect(page).to have_no_content plaintext
    end

    it "revokes a token", :aggregate_failures do
      token = ApiToken.issue(user: admin, name: "old script")

      visit "/admin/api_tokens"
      within "#api-token-#{token.id}" do
        click_on "Revoke"
      end

      expect(page).to have_content "API token was revoked."
      expect(page).to have_no_content "old script"
      expect(ApiToken.exists?(token.id)).to be(false)
    end

    it "only lists the admin's own tokens" do
      create(:api_token, name: "someone else's")

      visit "/admin/api_tokens"

      expect(page).to have_no_content "someone else's"
    end
  end

  context "when logged in as a non-admin" do
    it "denies access" do
      login_as create(:user)

      visit "/admin/api_tokens"

      expect(page).to have_content "Access Denied"
    end
  end
end
