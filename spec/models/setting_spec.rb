# == Schema Information
#
# Table name: settings
#
#  id                          :bigint           not null, primary key
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
end
