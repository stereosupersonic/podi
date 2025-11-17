require "capybara_helper"

describe "Statistics", type: :system do
  let!(:setting) { create(:setting) }

  context "when logged in as admin" do
    let(:admin) { create(:user, :admin) }

    before { login_as admin }

    it "overview page" do
      published_on = 8.days.ago.to_date
      episode = create(:episode, published_on: published_on, title: "Soli Wartenberg", number: 2)

      create(:event, episode: episode, created_at: 8.hours.ago)
      create(:event, episode: episode, created_at: 3.days.ago)
      create(:event, episode: episode, created_at: 7.days.ago)

      travel_to Time.current.beginning_of_day do
        visit "/"
        click_on "Statistics"

        within "#current_statistics" do
          expect(page).to have_selector "h2", text: "Current Statistics"
          expect(page).to have_table_with_exact_data([ [
                                                       "Titel",
                                                       "Published",
                                                       "last 12h",
                                                       "last 24h",
                                                       "last 3 days",
                                                       "last 1 week",
                                                       "last 30 days",
                                                       "last 60 days",
                                                       "last 12 month",
                                                       "last 24 month"
                                                     ],
                                                       [ "Soli Wartenberg",
                                                         "8 days",
                                                         "1",
                                                         "1",
                                                         "2",
                                                         "3",
                                                         "-",
                                                         "-",
                                                         "-",
                                                         "-" ] ])
        end

        none_visible_episode = create(:episode, published_on: 3.weeks.ago, title: "not shown", number: 1)
        create(:event, episode: none_visible_episode, created_at: 2.weeks.ago)

        visit "/"
        click_on "Statistics"

        within "#overall_statistics" do
          expect(page).to have_selector "h2", text: "Overall Statistics"
          expect(page).to have_table_with_exact_data([
                                                       [ "Titel", "Published", "After 12h", "After 1 day", "After 3 days", "After 1 week", "After 30 days",
                                                         "After 60 days", "After 12 month", "After 24 month", "overall" ],
                                                       [ "Soli Wartenberg", "8 days", "-", "-", "1", "2", "3", "3", "3",
                                                         "3", "3" ]
                                                     ])
        end
      end
    end
  end

  context "when logged in as user" do
    let(:user) { create(:user) }

    before { login_as user }

    it "does not have the link" do
      visit "/"

      expect(page).to have_no_link "Statistics"
    end

    it "gets Access Denied for admin functions" do
      visit "/admin/statistics"
      expect(page).to have_content "Access Denied"
    end
  end

  context "when not logged in" do
    it "does not have the link" do
      visit "/"

      expect(page).to have_no_link "Statistics"
    end

    it "gets Access Denied for admin functions" do
      visit "/admin/statistics"
      expect(page).to have_content "Access Denied"
    end
  end
end
