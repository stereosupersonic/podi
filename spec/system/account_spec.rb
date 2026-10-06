require "capybara_helper"

describe "Account", type: :system do
  let!(:setting) { create(:setting) }
  let(:user) { create(:user, first_name: "Joe", email: "joe@test.com") }

  context "when logged in" do
    before { login_as user }

    it "changes the name without the current password", :aggregate_failures do
      visit "/"
      click_on "Account"
      expect(page).to have_css "h1", text: "Account"

      fill_in "First name", with: "Jane"
      click_on "Save"

      expect(page).to have_content "Account was successfully updated."
      expect(user.reload.first_name).to eq("Jane")
    end

    it "changes email and password with the current password", :aggregate_failures do
      visit "/account/edit"

      fill_in "Email", with: "jane@test.com"
      fill_in "Password", with: "Secret456!"
      fill_in "Password confirmation", with: "Secret456!"
      click_on "Save"
      expect(page).to have_content "Current password is incorrect"

      fill_in "Password", with: "Secret456!"
      fill_in "Password confirmation", with: "Secret456!"
      fill_in "Current password", with: LoginHelpers::DEFAULT_TEST_PASSWORD
      click_on "Save"

      expect(page).to have_content "Account was successfully updated."
      expect(user.reload.email).to eq("jane@test.com")
      expect(user.authenticate("Secret456!")).to eq(user)
    end
  end

  context "when logged out" do
    it "asks to sign in" do
      visit "/account/edit"

      expect(page).to have_content "Please sign in to continue"
    end
  end
end
