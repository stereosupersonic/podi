require "capybara_helper"

describe "Jobs", type: :system do
  let!(:setting) { create(:setting) }

  context "when logged in as admin" do
    let(:admin) { create(:user, :admin) }

    before { login_as admin }

    it "has a Jobs link pointing to Sidekiq" do
      visit "/"

      expect(page).to have_link "Jobs", href: "/sidekiq"
    end
  end

  context "when logged in as user" do
    let(:user) { create(:user) }

    before { login_as user }

    it "does not have Jobs link" do
      visit "/"

      expect(page).to have_no_link "Jobs"
    end
  end

  context "when not logged in" do
    it "does not have Jobs link" do
      visit "/"

      expect(page).to have_no_link "Jobs"
    end
  end
end
