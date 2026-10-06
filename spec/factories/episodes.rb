# == Schema Information
#
# Table name: episodes
#
#  id              :bigint(8)        not null, primary key
#  active          :boolean          default(FALSE)
#  artwork_url     :string
#  chapter_marks   :text
#  description     :text             not null
#  downloads_count :integer          default(0)
#  image_data      :text
#  nodes           :text
#  number          :integer          default(0), not null, uniquely indexed
#  published_on    :date             indexed
#  rss_feed        :boolean          default(TRUE), indexed
#  slug            :string           not null, uniquely indexed
#  tags            :text             default([]), not null, is an Array, indexed
#  title           :string           not null, uniquely indexed
#  transcript      :text
#  visible         :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :episode do
    sequence(:title) { |n| "Soli Wartenberg #{n}" }
    slug { "#{number.to_s.rjust(3, '0')} #{title}".parameterize }
    description { "we talk about bikes and things" }
    artwork_url { "https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/#{slug}.jpg" }
    nodes { "* some nodes" }
    tags { [] }
    # image_data { TestData.image_data }
    downloads_count { 1 }
    published_on { Time.current.to_date }
    active { true }
    sequence(:number)
    audio { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/test-001.mp3"), "audio/mpeg") }
    after :create do |episode|
      episode.audio.analyze
    end
  end
end
