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

class Setting < ApplicationRecord
  # https://podcasting2.org/docs/podcast-namespace/tags/guid
  PODCAST_GUID_NAMESPACE = "ead4c236-bf58-58c6-a2c6-a6b28d128cb6".freeze

  # The podcast's permanent ID in the feed. Generated once from the feed URL and never changed afterwards,
  # so it survives a move to another domain.
  attribute :podcast_guid, :string, default: -> { generate_podcast_guid }

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
  validates(:podcast_guid, presence: true)

  def self.generate_podcast_guid
    feed_url = URI(Rails.application.routes.url_helpers.episodes_url(format: :rss))
    Digest::UUID.uuid_v5(PODCAST_GUID_NAMESPACE, "#{feed_url.host}#{feed_url.path}")
  end

  def self.current
    Setting.order(:created_at).last || raise("no setting")
  end

  def rss_url
    Rails.application.routes.url_helpers.episodes_url(format: :rss)
  end

  def canonical_url
    Rails.application.routes.url_helpers.root_url.chomp("/")
  end
end
