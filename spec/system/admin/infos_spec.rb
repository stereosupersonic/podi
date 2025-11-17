require "capybara_helper"

describe "Info", type: :system do
  let!(:setting) { create(:setting) }

  context "when logged in as admin" do
    let(:admin) { create(:user, :admin) }

    before { login_as admin }

    it "show infos" do
      visit "/"
      click_on "Info"
      expect(page).to have_selector "h1", text: "Info"
      within ".dev" do
        expect(page).to have_selector "h3", text: "Development"
        expect(page).to have_content(/Ruby-Version:.*3/)
        expect(page).to have_content(/Rails-Version:.*8/)
      end

      within ".env" do
        expect(page).to have_selector "h3", text: "ENV"
        expect(page).to have_content("HOME:")
      end

      within ".functions" do
        expect(page).to have_link("Raise rails exception")
        expect(page).to have_link("Raise js exception")
      end
    end

    it "raises text exeption" do
      visit "/"
      click_on "Info"

      within ".functions" do
        expect do
          click_link("Raise rails exception")
        end.to raise_error(RuntimeError)
      end
    end
  end

  context "when logged in as user" do
    let(:user) { create(:user) }

    before { login_as user }

    it "does not have Adminstration link" do
      visit "/"

      expect(page).to have_no_link "Info"
    end

    it "gets Access Denied for admin functions" do
      visit "/admin/info"
      expect(page).to have_content "Access Denied"
    end
  end

  context "when not logged in" do
    it "does not have setting link" do
      visit "/"

      expect(page).to have_no_link "setting"
    end

    it "gets Access Denied for admin functions" do
      visit "/admin/info"
      expect(page).to have_content "Access Denied"
    end
  end
end
