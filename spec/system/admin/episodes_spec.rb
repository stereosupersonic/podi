require "capybara_helper"

describe "Administrate Episodes", type: :system do
  context "when logged in as admin" do
    let(:admin) { FactoryBot.create :user, :admin }

    before { login_as admin }

    it "overview page" do
      episode = FactoryBot.create :episode, title: "Soli Wartenberg", number: 1

      visit "/"
      click_on "Administration"
      expect(page).to have_selector "h1", text: "Episodes"

      expect(page).to have_table_with_exact_data([
                                                   ["Epsiode",
                                                    "Title",
                                                    "downloads_count",
                                                    "published_on",
                                                    "",
                                                    ""],
                                                   ["001",
                                                    "Soli Wartenberg",
                                                    "1",
                                                    episode.published_on.strftime("%d.%m.%Y"),
                                                    "Edit",
                                                    "Show"]
                                                 ])
    end

    it "create a new episode" do
      published_on = Date.current

      visit "/"
      click_on "Administration"

      click_on "Add"

      expect(page).to have_text "New Episode"

      click_on "Save"
      expect(page).to have_content "Title can't be blank"
      expect(page).to have_content "Description can't be blank"
      expect(page).to have_content "File url can't be blank"
      expect(page).to have_content "Published on can't be blank"
      expect(page).to have_content "File size can't be blank"
      expect(page).to have_content "File duration can't be blank"

      fill_in "Title", with: "Talk about shit"
      fill_in "Description", with: "more alk about shit"
      fill_in "File url", with: "https:\\blah.test\001-test.mp3"
      fill_in "Published on", with: published_on
      fill_in "File size", with: 1000
      fill_in "File duration", with: 123_456
      fill_in "Artwork url", with: "https:\\blah.test\001-test.png"

      click_on "Save"

      expect(page).to have_content "Episode was successfully created."
      expect(page).to have_table_with_exact_data([
                                                   ["Epsiode", "Title", "downloads_count", "published_on", "", ""],
                                                   ["001",
                                                    "Talk about shit",
                                                    "0",
                                                    published_on.strftime("%d.%m.%Y"),
                                                    "Edit",
                                                    "Show"]
                                                 ])
      episode = Episode.last
      expect(episode.artwork_url).to eq "https:\\blah.test\001-test.png"
    end

    it "edits a existin episode" do
      episode = FactoryBot.create :episode, title: "foo", number: 2

      visit "/"
      click_on "Administration"

      click_on "Edit"

      expect(page).to have_text "Editing Episode"

      fill_in "Title", with: "test"
      fill_in "Nodes", with: "# my notes here *there*"
      fill_in "Artwork url", with: "https:\\blah.test\001-test-1.png"
      fill_in "Published on", with: 1.day.ago
      click_on "Save"

      expect(page).to have_content "Episode was successfully updated."
      expect(page).to have_table_with_exact_data([
                                                   ["Epsiode",
                                                    "Title",
                                                    "downloads_count",
                                                    "published_on",
                                                    "",
                                                    ""],
                                                   ["002",
                                                    "test",
                                                    "1",
                                                    1.day.ago.strftime("%d.%m.%Y"),
                                                    "Edit",
                                                    "Show"]
                                                 ])

      expect(episode.reload.slug).to eq "002-test"
      expect(episode.reload.artwork_url).to eq "https:\\blah.test\001-test-1.png"
    end
  end

  context "when logged in  as user" do
    let(:user) { FactoryBot.create :user }

    before { login_as user }

    it "does not have Adminstration link" do
      visit "/"

      expect(page).not_to have_link "Administration"
    end

    it "gets  Access Denied for admin functions" do
      visit "/admin/episodes"
      expect(page).to have_content "Access Denied"
    end
  end

  context "when not logged in" do
    it "does not have Adminstration link" do
      visit "/"

      expect(page).not_to have_link "Administration"
    end

    it "gets  Access Denied for admin functions" do
      visit "/admin/episodes"
      expect(page).to have_content "Access Denied"
    end
  end
end