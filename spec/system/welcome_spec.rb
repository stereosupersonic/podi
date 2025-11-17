require "capybara_helper"

describe "welcome", type: :system do
  let!(:setting) { create(:setting) }

  it "has an ready endpoint" do
    visit "/ready"

    expect(page).to have_content "OK"
  end

  context "when not logged in" do
    it "shows some basic informations" do
      visit "/"

      expect(page).to have_link "Wartenberger Podcast"
      expect(page).to have_link "Episoden"
      expect(page).to have_link "Über uns"
      expect(page).to have_title "Wartenberger Podcast"
      expect(page).to have_content setting.description
      expect(page).to have_no_link "Jobs"
      expect(page).to have_no_link "Events"
      expect(page).to have_no_link "Info"
      expect(page).to have_no_link "Administration"
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

      expect(page).to have_no_link "Administration"
      expect(page).to have_no_link "Account"
      expect(page).to have_no_link "Setting"
      expect(page).to have_no_link "Logout"
    end

    it "visit not existing bot url" do
      visit "/wp-login.php"

      expect(page).to have_content "Forbidden"
    end

    context "with last episodes" do
      it "shows nothing without a episode" do
        visit "/"

        expect(page).to have_no_css("#last-episodes")
        expect(page).to have_no_content "Letzte Episoden "
      end

      it "shows the last two episode" do
        create(:episode, title: "future Test", number: 5, published_on: 1.day.since)
        create(:episode, title: "last Test", number: 4, published_on: Time.zone.today)
        create(:episode, title: "inactive Test", number: 3, published_on: Time.zone.today, active: false)
        create(:episode, title: "second Test", number: 2, published_on: 1.day.ago)
        create(:episode, title: "first Test", number: 1, published_on: 2.weeks.ago)
        create(:episode, title: "about us", number: 0, published_on: 3.weeks.ago)
        visit "/"

        expect(page).to have_css("#last-episodes")
        expect(page).to have_content "Letzte Episoden"
        expect(page).to have_content "second Test"
        expect(page).to have_content "last Test"
        expect(page).to have_content "first Test"
        expect(page).to have_no_content "about us"
        expect(page).to have_no_content "future Test"
        expect(page).to have_no_content "nactive Test"
      end
    end

    context "with last episode" do
      it "shows nothing without a episode" do
        visit "/"

        expect(page).to have_no_css("#last-episode")
        expect(page).to have_no_content "Letzte Episode "
      end

      it "shows the last episode" do
        create(:episode, title: "last Test", number: 2, published_on: Time.zone.today)
        create(:episode, title: "first Test", number: 1, published_on: 2.weeks.ago)
        visit "/"

        expect(page).to have_css("#last-episode")
        expect(page).to have_content "Letzte Episode"
        expect(page).to have_content "last Test"
      end

      it "shows the last episode not inactive" do
        create(:episode, title: "last Test", number: 2, published_on: Time.zone.today, active: false)
        create(:episode, title: "first Test", number: 1, published_on: 2.weeks.ago)
        visit "/"

        expect(page).to have_css("#last-episode")
        expect(page).to have_content "Letzte Episode"
        expect(page).to have_content "first Test"
      end

      it "shows the last episode not published" do
        create(:episode, title: "last Test", number: 2, published_on: 1.day.since)
        create(:episode, title: "first Test", number: 1, published_on: 2.weeks.ago)
        visit "/"

        expect(page).to have_css("#last-episode")
        expect(page).to have_content "Letzte Episode"
        expect(page).to have_content "first Test"
      end

      it "has an short cut with the nummer" do
        create(:episode, title: "first Test", number: 1, published_on: 2.weeks.ago)
        visit "/001"

        expect(page).to have_title "first Test"
        expect(page).to have_content "we talk about bikes and things"
      end

      it "has an short cut with the nummer and redirects to 404 if number not exits" do
        visit "/001"

        expect(page).to have_title "The page you were looking for doesn’t exist (404 Not found)"
      end
    end
  end

  context "when logged in as user" do
    let(:user) { create(:user) }

    before { login_as user }

    it "shows special links when you are an admin" do
      visit "/"

      expect(page).to have_no_link "Administration"
      expect(page).to have_no_link "Setting"
      expect(page).to have_no_link "Jobs"
      expect(page).to have_no_link "Events"
      expect(page).to have_no_link "Info"

      expect(page).to have_link "Account"
      expect(page).to have_link "Logout"
    end

    it "logouts an user" do
      visit "/"

      click_link "Logout"

      expect(page).to have_content "Signed out successfully."
    end
  end

  context "when logged in as admin" do
    let(:admin) { create(:user, :admin) }

    before { login_as admin }

    it "shows special links when you are an admin" do
      visit "/"

      expect(page).to have_link "Administration"
      expect(page).to have_link "Account"
      expect(page).to have_link "Jobs"
      expect(page).to have_link "Events"
      expect(page).to have_link "Info"
      expect(page).to have_link "Logout"
    end
  end
end
