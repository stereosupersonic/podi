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

FactoryBot.define do
  factory :setting do
    title { "Wartenberger Podcast" }

    description { "Der Podcast über und um den Markt Wartenberg" }

    language { :de }

    seo_keywords { %w[Podcast Wartenberg Oberbayern München Bayern Regional].join(", ") }

    author { "Michael Deimel, Thomas Rademacher" }

    owner { "Michael Deimel" }

    email { "admin@wartenberger.de" }

    logo_url { "https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/images/itunes-logo-1400x1400.jpg" }

    itunes_category { "News" }

    itunes_sub_category { "Politics" }

    itunes_language { "de-de" }

    default_episode_artwork_url { "https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/episode-default-logo.png" }

    about_episode_number { 1 }

    facebook_url { "https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563" }

    youtube_url { "https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg" }

    twitter_url { "https://twitter.com/WartenbergerPod" }

    instagram_url { "https://www.instagram.com/wartenbergerpodcast" }

    itunes_url { "https://podcasts.apple.com/de/podcast/wartenberger-podcast/id1546458413" }

    spotify_url { "https://open.spotify.com/show/3EkNs5dt2Uix1oRWREyTOF" }
  end
end
