# == Schema Information
#
# Table name: settings
#
#  id                          :integer          not null, primary key
#  title                       :string           not null
#  description                 :text             not null
#  language                    :string           not null
#  seo_keywords                :text
#  author                      :string           not null
#  owner                       :string           not null
#  email                       :string           not null
#  logo_url                    :string           not null
#  default_episode_artwork_url :string           not null
#  itunes_category             :string           not null
#  itunes_sub_category         :string           not null
#  itunes_language             :string           not null
#  about_episode_number        :integer          not null
#  facebook_url                :string
#  youtube_url                 :string
#  twitter_url                 :string
#  instagram_url               :string
#  itunes_url                  :string
#  spotify_url                 :string
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
  validates(:facebook_url, url: true)
  validates(:youtube_url, url: true)
  validates(:twitter_url, url: true)
  validates(:instagram_url, url: true)
  validates(:itunes_url, url: true)
  validates(:spotify_url, url: true)

  def self.current
    Setting.order(:id).last || raise("no setting")
  end

  def rss_url
    Rails.application.routes.url_helpers.episodes_url(format: :rss)
  end

  def canonical_url
    Rails.application.routes.url_helpers.root_url.chomp("/")
  end
end
