require "capybara_helper"

describe "Flash messages", type: :system do
  let(:user) { create(:user, :admin) }

  before do
    create(:setting)
    visit "/login"
    fill_in "Email", with: user.email
  end

  it "shows a notice as success" do
    fill_in "Password", with: LoginHelpers::DEFAULT_TEST_PASSWORD
    click_on "Sign In"

    expect(page).to have_css ".alert-success", text: "Signed in successfully"
  end

  it "shows an alert as warning" do
    fill_in "Password", with: "wrong"
    click_on "Sign In"

    expect(page).to have_css ".alert-warning", text: "Invalid email or password"
  end
end
