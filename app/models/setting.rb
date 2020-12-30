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
#  google_url                  :string
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
class Setting < ApplicationRecord
  validates(:title, presence: true)
  validates(:description, presence: true)
  validates(:email, presence: true)
  validates(:logo_url, presence: true, url: true)
  validates(:language, presence: true)
  validates(:itunes_language, presence: true)
  validates(:itunes_category, presence: true)
  validates(:itunes_sub_category, presence: true)
  validates(:owner, presence: true)
  validates(:author, presence: true)
  validates(:default_episode_artwork_url, presence: true, url: true)

  def self.current
    Setting.last || raise("no setting")
  end

  def rss_url
    Rails.application.routes.url_helpers.episodes_url(format: :rss)
  end

  def canonical_url
    Rails.application.routes.url_helpers.root_url.chomp("/")
  end
end
