require "capybara_helper"

# class ActiveJob::QueueAdapters::TestAdapter
#   def activating(&block)
#    # block.call
#   end
# end

describe "Jobs", type: :system do
  let!(:setting) { create(:setting) }

  context "when logged in as admin" do
    let(:admin) { create(:user, :admin) }

    before { login_as admin }

    xit "show jobs" do
      visit "/"
      click_on "Jobs"

      expect(page).to have_content "Jobs"
    end
  end

  context "when logged in as user" do
    let(:user) { create(:user) }

    before { login_as user }

    it "does not have Jobs link" do
      visit "/"

      expect(page).to have_no_link "Jobs"
    end

    it "gets Access Denied for admin functions" do
      visit "/jobs"

      expect(page).to have_content "Access Denied"
    end
  end

  context "when not logged in" do
    it "does not have Jobs link" do
      visit "/"

      expect(page).to have_no_link "Jobs"
    end

    it "gets Access Denied for admin functions" do
      visit "/jobs"
      expect(page).to have_content "Access Denied"
    end
  end
end
