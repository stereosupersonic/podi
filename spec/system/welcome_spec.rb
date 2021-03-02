require "capybara_helper"

describe "welcome", type: :system do
  let!(:setting) { FactoryBot.create(:setting) }

  context "when not logged in" do
    it "shows some basic informations" do
      visit "/"

      expect(page).to have_link "Wartenberger Podcast"
      expect(page).to have_title "Wartenberger Podcast"
      expect(page).to have_content setting.description
    end

    it "shows the title" do
      visit "/"

      expect(page).to have_content "Wartenberger Podcast"
      expect(page).to have_title "Wartenberger Podcast"
    end

    it "has some global meta tags" do
      visit "/"

      expect(page).to have_meta("author", "Michael Deimel, Thomas Rademacher")
      expect(page).to have_meta("keywords", "Podcast, Wartenberg, Oberbayern, München, Bayern, Regional")
      expect(page).to have_meta("description", "Der Podcast über und um den Markt Wartenberg")
      expect(page).to have_meta("og:locale", "de_DE")
      expect(page).to have_meta "og:title", "Wartenberger Podcast"
      expect(page).to have_meta "og:url", "http://wartenberger.test.com"
      expect(page).to have_meta "og:description", "Der Podcast über und um den Markt Wartenberg"
      expect(page).to have_meta "og:image", "https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/images/itunes-logo-1400x1400.jpg"

      expect(page).to have_meta "twitter:card", "summary"
      expect(page).to have_meta "twitter:site", "@WartenbergerPod"
      expect(page).to have_meta "twitter:creator", "@WartenbergerPod"
    end

    it "shows the about page" do
      visit "/"
      click_link "Über uns"

      expect(page).to have_content "Über Uns"
      expect(page).to have_title "Über den Podcast"
    end

    it "shows the impressum page" do
      visit "/"
      click_link "Impressum"

      expect(page).to have_selector "h1", text: "Impressum"
      expect(page).to have_title "Impressum"
    end

    it "shows the privacy page" do
      visit "/"

      click_link "Datenschutz"

      expect(page).to have_selector "h1", text: "Datenschutz"
      expect(page).to have_title "Datenschutz"
    end

    it "dont shows special links when you are not an admin" do
      visit "/"

      expect(page).not_to have_link "Administration"
      expect(page).not_to have_link "Account"
      expect(page).not_to have_link "Setting"
      expect(page).not_to have_link "Logout"
    end

    it "visit not existing bot url" do
      visit "/wp-login.php"

      expect(page).to have_content "Forbidden"
    end

    context "with last episodes" do
      it "shows nothing without a episode" do
        visit "/"

        expect(page).not_to have_css("#last-episodes")
        expect(page).not_to have_content "Letzte Episoden "
      end

      it "shows the last two episode" do
        FactoryBot.create :episode, title: "future Test", number: 5, published_on: 1.day.since
        FactoryBot.create :episode, title: "last Test", number: 4, published_on: Time.zone.today
        FactoryBot.create :episode, title: "inactive Test", number: 3, published_on: Time.zone.today, active: false
        FactoryBot.create :episode, title: "second Test", number: 2, published_on: 1.day.ago
        FactoryBot.create :episode, title: "first Test", number: 1, published_on: 2.weeks.ago
        FactoryBot.create :episode, title: "about us", number: 0, published_on: 3.weeks.ago
        visit "/"

        expect(page).to have_css("#last-episodes")
        expect(page).to have_content "Letzte Episoden"
        expect(page).to have_content "second Test"
        expect(page).to have_content "last Test"
        expect(page).to have_content "first Test"
        expect(page).not_to have_content "about us"
        expect(page).not_to have_content "future Test"
        expect(page).not_to have_content "nactive Test"
      end
    end

    context "with last episode" do
      it "shows nothing without a episode" do
        visit "/"

        expect(page).not_to have_css("#last-episode")
        expect(page).not_to have_content "Letzte Episode "
      end

      it "shows the last episode" do
        FactoryBot.create :episode, title: "last Test", number: 2, published_on: Time.zone.today
        FactoryBot.create :episode, title: "first Test", number: 1, published_on: 2.weeks.ago
        visit "/"

        expect(page).to have_css("#last-episode")
        expect(page).to have_content "Letzte Episode"
        expect(page).to have_content "last Test"
      end

      it "shows the last episode not inactive" do
        FactoryBot.create :episode, title: "last Test", number: 2, published_on: Time.zone.today, active: false
        FactoryBot.create :episode, title: "first Test", number: 1, published_on: 2.weeks.ago
        visit "/"

        expect(page).to have_css("#last-episode")
        expect(page).to have_content "Letzte Episode"
        expect(page).to have_content "first Test"
      end

      it "shows the last episode not published" do
        FactoryBot.create :episode, title: "last Test", number: 2, published_on: 1.day.since
        FactoryBot.create :episode, title: "first Test", number: 1, published_on: 2.weeks.ago
        visit "/"

        expect(page).to have_css("#last-episode")
        expect(page).to have_content "Letzte Episode"
        expect(page).to have_content "first Test"
      end

      it "has an short cut with the nummer" do
        FactoryBot.create :episode, title: "first Test", number: 1, published_on: 2.weeks.ago
        visit "/001"

        expect(page).to have_title "first Test"
        expect(page).to have_content "we talk about bikes and things"
      end

      it "has an short cut with the nummer and redirects to 404 if number not exits" do
        visit "/001"

        expect(page).to have_title "The page you were looking for doesn't exist (404)"
      end
    end
  end

  context "when logged in as user" do
    let(:user) { FactoryBot.create :user }

    before { login_as user }

    it "shows special links when you are an admin" do
      visit "/"

      expect(page).not_to have_link "Administration"
      expect(page).not_to have_link "Setting"

      expect(page).to have_link "Account"
      expect(page).to have_link "Logout"
    end
  end

  context "when logged in as admin" do
    let(:admin) { FactoryBot.create :user, :admin }

    before { login_as admin }

    it "shows special links when you are an admin" do
      visit "/"

      expect(page).to have_link "Administration"
      expect(page).to have_link "Account"
      expect(page).to have_link "Account"
      expect(page).to have_link "Logout"
    end
  end
end
