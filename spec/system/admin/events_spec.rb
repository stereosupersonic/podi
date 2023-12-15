require "capybara_helper"

describe "Events", type: :system do
  let!(:setting) { create(:setting) }

  context "when logged in as admin" do
    let(:admin) { create(:user, :admin) }

    before { login_as admin }

    it "overview page" do
      episode = create(:episode, title: "Soli Wartenberg", number: 1)
      event = create(:event, episode: episode, geo_data: nil, downloaded_at: Time.zone.parse("2012-07-11 21:00"))
      create(:event, episode: episode, created_at: 1.day.ago, downloaded_at: Time.zone.parse("2021-01-01 21:00"))

      visit "/"
      click_on "Events"

      expect(page).to have_selector "h1", text: "Events"
      expect(page).to have_text("2 Events")

      expect(page).to have_table_with_exact_data([
        ["Date",
          "Episode",
          "Info",
          "Geo Info",
          ""],
        ["01.01.2021 21:00",
          "001 Soli Wartenberg",
          "127.0.0.1 - Chrome - desktop",
          "Germany - Bavaria - 85368 - Moosburg - Deutsche Telekom AG",
          "Show"],
        ["11.07.2012 21:00",
          "001 Soli Wartenberg",
          "127.0.0.1 - Chrome - desktop",
          "",
          "Show"]
      ])
      within "#event-#{event.id}" do
        click_on "Show"
      end
      expect(page).to have_current_path("/admin/events/#{event.id}")
      expect(page).to have_selector "h1", text: "001 Soli Wartenberg"
      expect(page).to have_content "11.07.2012 21:00"

      expect(page).to have_selector "h3", text: "Data"
      expect(page).to have_content "client_name: Chrome"
    end

    it "filter overview page by episode" do
      episode = create(:episode, title: "Soli Wartenberg", number: 1)
      episode2 = create(:episode, title: "Feuerwehr Wartenberg", number: 2)
      create(:event, episode: episode, downloaded_at: Time.zone.parse("2021-01-01 21:00"))
      create(:event, episode: episode2, created_at: 1.day.ago)
      create(:event, episode: episode2, created_at: 1.day.ago)

      visit "/admin/events?episode_id=#{episode.id}"

      expect(page).to have_selector "h1", text: "Events"
      expect(page).to have_text("1 Events")

      expect(page).to have_table_with_exact_data([
        ["Date",
          "Episode",
          "Info",
          "Geo Info",
          ""],
        ["01.01.2021 21:00",
          "001 Soli Wartenberg",
          "127.0.0.1 - Chrome - desktop",
          "Germany - Bavaria - 85368 - Moosburg - Deutsche Telekom AG",
          "Show"]
      ])
    end
  end

  context "when logged in  as user" do
    let(:user) { create(:user) }

    before { login_as user }

    it "does not have the link" do
      visit "/"

      expect(page).not_to have_link "Events"
    end

    it "gets Access Denied for admin functions" do
      visit "/admin/events"
      expect(page).to have_content "Access Denied"
    end
  end

  context "when not logged in" do
    it "does not have the link" do
      visit "/"

      expect(page).not_to have_link "Events"
    end

    it "gets Access Denied for admin functions" do
      visit "/admin/events"
      expect(page).to have_content "Access Denied"
    end
  end
end
