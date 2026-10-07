# == Schema Information
#
# Table name: episode_current_statistics
#
#  a12h         :bigint(8)
#  a12m         :bigint(8)
#  a14d         :bigint(8)
#  a18m         :bigint(8)
#  a1d          :bigint(8)
#  a24m         :bigint(8)
#  a30d         :bigint(8)
#  a3d          :bigint(8)
#  a3m          :bigint(8)
#  a60d         :bigint(8)
#  a6m          :bigint(8)
#  a7d          :bigint(8)
#  cnt          :bigint(8)
#  day          :text
#  number       :integer
#  published_on :date
#  title        :string
#  week         :integer
#  year         :integer
#  episode_id   :bigint(8)
#

require "rails_helper"

RSpec.describe EpisodeCurrentStatistic, type: :model do
  subject(:statistic) { described_class.find_by!(episode_id: episode.id) }

  let!(:setting) { create(:setting) }
  let!(:episode) { create(:episode, published_on: 2.days.ago.to_date) }

  context "without downloads" do
    it "counts zero downloads" do
      expect(statistic.cnt).to eq(0)
    end
  end

  context "with downloads" do
    before do
      create(:event, episode: episode, created_at: 13.hours.ago)
      create(:event, episode: episode, created_at: 1.hour.ago)
    end

    it "counts every download" do
      expect(statistic.cnt).to eq(2)
    end

    it "counts only downloads of the last 12 hours in a12h" do
      expect(statistic.a12h).to eq(1)
    end
  end
end
