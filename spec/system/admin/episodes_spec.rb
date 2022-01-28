require "capybara_helper"

describe "Administrate Episodes", type: :system do
  let!(:setting) { FactoryBot.create(:setting) }
  let(:last_episode) { EpisodePresenter.new Episode.last }

  context "when logged in as admin" do
    let(:admin) { FactoryBot.create :user, :admin }

    before { login_as admin }

    it "overview page" do
      episode = FactoryBot.create :episode, title: "Soli Wartenberg", number: 1

      visit "/"
      click_on "Administration"
      expect(page).to have_selector "h1", text: "Episodes"

      expect(page).to have_table_with_exact_data([
        ["Published",
          "Epsiode",
          "Cover",
          "Title",
          "Size",
          "Duration",
          "Filename",
          "Downloads",
          "Published",
          "",
          ""],
        ["",
          "001",
          "",
          "Soli Wartenberg",
          "51.4 KB",
          "00:00:03",
          "test-001.mp3",
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
      expect(page).to have_content "Published on can't be blank"
      expect(page).to have_content "Audio can't be blank"

      fill_in "Title", with: "Talk about shit"
      fill_in "Description", with: "more alk about shit"
      fill_in "Nodes", with: "* some thing"
      fill_in "Published on", with: published_on

      fill_in "Chapter marks", with: %(
        00:00:01 Intro
        00:00:41 Begrüßung der Mannschaft
        00:01:30 Vorstellung
      )

      fill_in "Artwork url", with: "https://test.com/001-test.png"
      attach_file "Audio", Rails.root.join("spec/fixtures/test-002.mp3")

      click_on "Save"
      perform_enqueued_jobs_now!

      expect(page).to have_content "Episode was successfully created."
      expect(page).to have_current_path "/admin/episodes"

      expect(last_episode.duration).to eq 8
      expect(last_episode.audio_size).to eq 114_031

      visit "/admin/episodes"
      expect(page).to have_table_with_exact_data([
        ["Published",
          "Epsiode",
          "Cover",
          "Title",
          "Size",
          "Duration",
          "Filename",
          "Downloads",
          "Published",
          "",
          ""],
        ["",
          "001",
          "",
          "Talk about shit",
          "111 KB",
          "00:00:08",
          "test-002.mp3",
          "0",
          published_on.strftime("%d.%m.%Y"),
          "Edit",
          "Show"]
      ])

      # expect(episode.artwork_url).to eq "https://test.com/001-test.png"
      expect(last_episode.chapter_marks.squish).to eq %(00:00:01 Intro
        00:00:41 Begrüßung der Mannschaft
        00:01:30 Vorstellung).squish
    end

    it "edits a existin episode" do
      FactoryBot.create :episode, title: "balh", number: 1
      episode2 = FactoryBot.create :episode, title: "foo", number: 2, description: "should be foo"

      visit "/"
      click_on "Administration"

      within "#episode-#{episode2.id}" do
        click_on "Edit"
      end

      expect(page).to have_text "Editing Episode"

      fill_in "Title", with: ""
      click_on "Save"

      expect(page).to have_content "Title can't be blank"

      fill_in "Title", with: "balh"
      fill_in "Nodes", with: "# my notes here *there*"

      click_on "Save"
      expect(page).to have_content "Title has already been taken"

      fill_in "Title", with: "test"
      fill_in "Nodes", with: "# my notes here *there*"

      fill_in "Published on", with: 1.day.ago
      fill_in "Description", with: "should be foo changed"
      fill_in "Chapter marks", with: %(
        00:00:01 Intro
        00:00:41 Begrüßung der Leute
        00:01:30 Bereitstellung
      )

      attach_file "Audio", Rails.root.join("spec/fixtures/test-002.mp3")
      # attach_file "Image", Rails.root.join("spec/fixtures/001-vorstellung.jpg")

      click_on "Save"
      perform_enqueued_jobs_now!

      expect(page).to have_content "Episode was successfully updated."
      expect(page).to have_current_path "/admin/episodes"

      expect(episode2.reload.duration).to eq 8
      expect(episode2.reload.audio_size).to eq 114031

      visit "/admin/episodes"
      expect(page).to have_table_with_exact_data([
        ["Published",
          "Epsiode",
          "Cover",
          "Title",
          "Size",
          "Duration",
          "Filename",
          "Downloads",
          "Published",
          "",
          ""],
        ["",
          "002",
          "",
          "test",
          "111 KB",
          "00:00:08",
          "test-002.mp3",
          "1",
          1.day.ago.strftime("%d.%m.%Y"),
          "Edit",
          "Show"],
        ["",
          "001",
          "",
          "balh",
          "51.4 KB",
          "00:00:03",
          "test-001.mp3",
          "1",
          Time.current.strftime("%d.%m.%Y"),
          "Edit",
          "Show"]
      ])

      expect(episode2.reload.slug).to eq "002-test"
      expect(episode2.chapter_marks.squish).to eq %(00:00:01 Intro
        00:00:41 Begrüßung der Leute
        00:01:30 Bereitstellung).squish
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
