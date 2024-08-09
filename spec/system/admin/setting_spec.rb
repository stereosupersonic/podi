require "capybara_helper"

describe "Setting", type: :system do
  let!(:setting) { create(:setting) }

  context "when logged in as admin" do
    let(:admin) { create(:user, :admin) }

    before { login_as admin }

    it "edit page" do
      visit "/"
      click_on "Setting"
      expect(page).to have_selector "h1", text: "Edit Setting"
      fill_in "Title", with: ""

      click_on "Save"
      expect(page).to have_content "Title can't be blank"

      fill_in "Title", with: "Pod Blah"
      fill_in "Description", with: "more Talk about shit"
      fill_in "Logo url", with: "https://test.de/pic.jpg"

      fill_in "Language", with: "en"
      fill_in "Itunes language", with: "en-en"
      fill_in "Itunes category", with: "Olds"
      fill_in "Itunes sub category", with: "jokes"

      fill_in "Seo keywords", with: "bayern, oberbayern"
      fill_in "Author", with: "Joe Doe, Mr. Tee"

      fill_in "Owner", with: "Joe Doe"
      fill_in "Email", with: "j.doe@test.de"

      fill_in "Default episode artwork url", with: "https://test.de/art.jpg"
      fill_in "About episode number", with: 2

      fill_in "Facebook url", with: "https://test.com/facebook"
      fill_in "Youtube url", with: "https://test.com/youtube"
      fill_in "Twitter url", with: "https://test.com/twitter"
      fill_in "Instagram url", with: "https://test.com/instagram"
      fill_in "Itunes url", with: "https://test.com/itunes"
      fill_in "Spotify url", with: "https://test.com/spotify"
      fill_in "Google url", with: "https://test.com/google"

      click_on "Save"

      expect(page).to have_content "Setting was successfully updated"

      setting = Setting.current.reload
      expect(setting.title).to eq "Pod Blah"
      expect(setting.description).to eq "more Talk about shit"
      expect(setting.language).to eq "en"
      expect(setting.itunes_language).to eq "en-en"
      expect(setting.seo_keywords).to eq "bayern, oberbayern"
      expect(setting.author).to eq "Joe Doe, Mr. Tee"
      expect(setting.owner).to eq "Joe Doe"
      expect(setting.email).to eq "j.doe@test.de"
      expect(setting.itunes_category).to eq "Olds"
      expect(setting.itunes_sub_category).to eq "jokes"
      expect(setting.logo_url).to eq "https://test.de/pic.jpg"
      expect(setting.default_episode_artwork_url).to eq "https://test.de/art.jpg"
      expect(setting.about_episode_number).to eq 2

      expect(setting.facebook_url).to eq "https://test.com/facebook"
      expect(setting.youtube_url).to eq "https://test.com/youtube"
      expect(setting.twitter_url).to eq "https://test.com/twitter"
      expect(setting.instagram_url).to eq "https://test.com/instagram"
      expect(setting.itunes_url).to eq "https://test.com/itunes"
      expect(setting.spotify_url).to eq "https://test.com/spotify"
      expect(setting.google_url).to eq "https://test.com/google"
    end
  end

  context "when logged in as user" do
    let(:user) { create(:user) }

    before { login_as user }

    it "does not have Adminstration link" do
      visit "/"

      expect(page).not_to have_link "Setting"
    end

    it "gets Access Denied for admin functions" do
      visit "/admin/setting/edit"
      expect(page).to have_content "Access Denied"
    end
  end

  context "when not logged in" do
    it "does not have setting link" do
      visit "/"

      expect(page).not_to have_link "setting"
    end

    it "gets Access Denied for admin functions" do
      visit "/admin/setting/edit"
      expect(page).to have_content "Access Denied"
    end
  end
end
