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
require "rails_helper"

RSpec.describe Episode, type: :model do
  it "has a valid factory" do
    episode = build(:episode)

    expect(episode).to be_valid
    assert episode.save!
  end

  describe ".published" do
    it "find active published ones the past" do
      episode = create(:episode, published_on: 1.day.ago, active: true)

      expect(described_class.published).to eq([ episode ])
    end

    it "find active published ones from today" do
      episode = create(:episode, published_on: Time.zone.today, active: true)

      expect(described_class.published).to eq([ episode ])
    end

    it "dont find inactive" do
      create(:episode, published_on: Time.zone.today, active: false)

      expect(described_class.published).to be_empty
    end

    it "dont find invisible" do
      create(:episode, published_on: Time.zone.today, visible: false)

      expect(described_class.published).to be_empty
    end

    it "dont find on from the future" do
      create(:episode, published_on: Time.zone.today + 1.day, active: false)

      expect(described_class.published).to be_empty
    end

    it "is ordered by number" do
      episode1 = create(:episode, number: 1)
      episode3 = create(:episode, number: 3)
      episode2 = create(:episode, number: 2)

      expect(described_class.published).to eq([ episode3, episode2, episode1 ])
    end
  end
end
