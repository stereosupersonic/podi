# == Schema Information
#
# Table name: episode_statistics
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

RSpec.describe EpisodeStatistic, type: :model do
  subject(:statistic) { described_class.find_by!(episode_id: episode.id) }

  let!(:episode) { create(:episode, published_on: Date.current) }

  # The view only lists episodes published after the first download
  before { create(:event, created_at: 2.days.ago) }

  context "without downloads" do
    it "counts zero downloads" do
      expect(statistic.cnt).to eq(0)
    end
  end

  context "with downloads" do
    before { create(:event, episode: episode) }

    it "counts every download" do
      expect(statistic.cnt).to eq(1)
    end
  end
end
