# == Schema Information
#
# Table name: settings
#
#  id                          :bigint(8)        not null, primary key
#  about_episode_number        :integer          not null
#  author                      :string           not null
#  default_episode_artwork_url :string           not null
#  description                 :text             not null
#  email                       :string           not null
#  facebook_url                :string
#  instagram_url               :string
#  itunes_category             :string           not null
#  itunes_language             :string           not null
#  itunes_sub_category         :string           not null
#  itunes_url                  :string
#  language                    :string           not null
#  logo_url                    :string           not null
#  owner                       :string           not null
#  podcast_guid                :string           not null
#  seo_keywords                :text
#  spotify_url                 :string
#  title                       :string           not null
#  twitter_url                 :string
#  youtube_url                 :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#

require "rails_helper"

RSpec.describe Setting, type: :model do
  it "has a valid factory" do
    setting = build(:setting)

    expect(setting).to be_valid
    assert setting.save!
  end

  %w[logo_url default_episode_artwork_url facebook_url youtube_url twitter_url instagram_url itunes_url
     spotify_url].each do |url|
    it "validates for a valid #{url}" do
      setting = build(:setting)
      setting.send("#{url}=", "invalid url")

      expect(setting).to be_invalid
      expect(setting.errors[url].join.to_s).to eq "is not a valid URL"
    end
  end

  describe "#podcast_guid" do
    it "is generated from the feed URL for a new setting" do
      expect(described_class.new.podcast_guid).to eq("154c266d-cf65-5c92-b754-a1192eebf4ce")
    end

    it "follows the Podcast Index example for podnews.net/rss" do
      allow(Rails.application.routes.url_helpers).to receive(:episodes_url).and_return("https://podnews.net/rss")

      expect(described_class.new.podcast_guid).to eq("9b024349-ccf0-5f69-a609-6b82873eab3c")
    end

    it "keeps a stored guid", :aggregate_failures do
      setting = create(:setting, podcast_guid: "2bac87e9-7f7b-581e-aea8-44d36776e94a")

      expect(setting.reload.podcast_guid).to eq("2bac87e9-7f7b-581e-aea8-44d36776e94a")
      expect(described_class.find(setting.id).podcast_guid).to eq("2bac87e9-7f7b-581e-aea8-44d36776e94a")
    end

    it "is required" do
      expect(build(:setting, podcast_guid: "")).to be_invalid
    end
  end
end
