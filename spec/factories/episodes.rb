# == Schema Information
#
# Table name: episodes
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE)
#  artwork_url     :string
#  chapter_marks   :text
#  description     :text             not null
#  downloads_count :integer          default(0)
#  image_data      :text
#  nodes           :text
#  number          :integer          default(0), not null
#  published_on    :date
#  rss_feed        :boolean          default(TRUE)
#  slug            :string           not null
#  title           :string           not null
#  visible         :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_episodes_on_number        (number) UNIQUE
#  index_episodes_on_published_on  (published_on)
#  index_episodes_on_rss_feed      (rss_feed)
#  index_episodes_on_slug          (slug) UNIQUE
#  index_episodes_on_title         (title) UNIQUE
#

FactoryBot.define do
  factory :episode do
    sequence(:title) { |n| "Soli Wartenberg #{n}" }
    slug { "#{number.to_s.rjust(3, "0")} #{title}".parameterize }
    description { "we talk about bikes and things" }
    artwork_url { "https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/#{slug}.jpg" }
    nodes { "* some nodes" }
    # image_data { TestData.image_data }
    downloads_count { 1 }
    published_on { Time.current.to_date }
    sequence(:number)
    audio { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/test-001.mp3"), "audio/mpeg") }
    after :create do |episode|
      episode.audio.analyze
    end
  end
end
