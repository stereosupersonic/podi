require "capybara_helper"

describe "Episodes", type: :system do
  let!(:setting) { create(:setting) }

  context "overview page" do
    it "shows only active episodes" do
      create(:episode, title: "future Test", number: 5, published_on: 1.day.since)
      create(:episode, title: "last Test", number: 4, published_on: Time.zone.today)
      create(:episode, title: "inactive Test", number: 3, published_on: Time.zone.today, active: false)
      create(:episode, title: "second Test", number: 2, published_on: 1.day.ago)
      create(:episode, title: "first Test", number: 1, published_on: 2.weeks.ago)

      visit "/episodes"

      expect(page).to have_selector "h1", text: "Alle Episoden"
      expect(page).to have_title "Alle Episoden"
      expect(page).to have_content "second Test"
      expect(page).to have_content "last Test"
      expect(page).to have_content "first Test"
      expect(page).to have_no_content "future Test"
      expect(page).to have_no_content "inactive Test"
    end
  end

  context "show page" do
    it "gets an epsiode by slug" do
      create(:episode, title: "Blah Test", number: 1)

      visit "/episodes/001-blah-test"

      expect(page).to have_content "Blah Test"
      expect(page).to have_title "Blah Test"
      expect(page).to have_meta "og:type", "article"
      expect(page).to have_meta "og:title", "Blah Test"
      expect(page).to have_meta "og:url", "http://wartenberger.test.com/episodes/001-blah-test"
      expect(page).to have_meta "og:description", "we talk about bikes and things"
      expect(page).to have_meta "og:image", "https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/001-blah-test.jpg"
      expect(page).to have_meta "og:audio", "http://wartenberger.test.com/episodes/001-blah-test.mp3"
    end

    it "gets an inactive epsiode by slug" do
      create(:episode, title: "Blah Test", number: 1, active: false)

      visit "/episodes/001-blah-test"

      expect(page).to have_content "Blah Test"
      expect(page).to have_title "Blah Test"
    end

    it "dont get an invisible epsiode by slug" do
      create(:episode, title: "Blah Test", number: 1, active: false, visible: false)

      visit "/episodes/001-blah-test"

      expect(page.status_code).to eq 404
      expect(page).to have_content "The page you were looking for doesn’t exist."
    end

    it "don't gets an epsiode by number" do
      create(:episode, title: "Blah Test", number: 1, visible: false)

      visit "/episodes/001-old-title"

      expect(page.status_code).to eq 404
      expect(page).to have_content "The page you were looking for doesn’t exist."

      visit "/episodes/1"

      expect(page.status_code).to eq 404
      expect(page).to have_content "The page you were looking for doesn’t exist."
    end

    it "gets an epsiode by number" do
      create(:episode, title: "Blah Test", number: 1)

      visit "/episodes/001-old-title"

      expect(page).to have_content "Blah Test"
      expect(page).to have_title "Blah Test"

      visit "/episodes/1"

      expect(page).to have_content "Blah Test"
      expect(page).to have_title "Blah Test"
    end

    it "gets an future epsiode by slug" do
      create(:episode, title: "Blah Test", number: 1, published_on: 1.day.since)

      visit "/episodes/001-blah-test"

      expect(page).to have_content "Blah Test"
      expect(page).to have_title "Blah Test"
    end

    it "gets an 404 by unknow slug" do
      visit "/episodes/001-blah-test"

      expect(page).to have_content "The page you were looking for doesn’t exist."
    end
  end
end
