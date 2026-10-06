require "capybara_helper"

describe "Users", type: :system do
  let!(:setting) { create(:setting) }
  let(:admin) { create(:user, :admin, email: "admin@test.com") }

  before { login_as admin }

  it "creates a user", :aggregate_failures do
    visit "/"
    click_on "Users"
    click_on "Add"

    click_on "Save"
    expect(page).to have_content "Email can't be blank"

    fill_in "First name", with: "Co"
    fill_in "Last name", with: "Host"
    fill_in "Email", with: "cohost@test.com"
    fill_in "user[password]", with: "Secret456!"
    fill_in "user[password_confirmation]", with: "Secret456!"
    check "Admin"
    click_on "Save"

    expect(page).to have_content "User was successfully created."
    expect(page).to have_content "cohost@test.com"
    expect(User.find_by(email: "cohost@test.com")).to be_admin
  end

  it "edits a user without changing the password", :aggregate_failures do
    user = create(:user, email: "cohost@test.com")

    visit "/admin/users"
    within "#user-#{user.id}" do
      click_on "Edit"
    end
    fill_in "Last name", with: "Smith"
    check "Admin"
    click_on "Save"

    expect(page).to have_content "User was successfully updated."
    expect(user.reload).to be_admin
    expect(user.authenticate(LoginHelpers::DEFAULT_TEST_PASSWORD)).to eq(user)
  end

  it "deletes a user", :aggregate_failures do
    user = create(:user, email: "cohost@test.com")

    visit "/admin/users"
    within "#user-#{user.id}" do
      click_on "Delete"
    end

    expect(page).to have_content "User was successfully deleted."
    expect(page).to have_no_content "cohost@test.com"
  end

  it "does not offer to delete or demote yourself", :aggregate_failures do
    visit "/admin/users"
    within "#user-#{admin.id}" do
      expect(page).to have_no_button "Delete"
      click_on "Edit"
    end

    expect(page).to have_no_field "Admin"
  end
end
