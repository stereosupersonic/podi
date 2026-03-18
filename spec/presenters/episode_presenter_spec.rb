require "rails_helper"

RSpec.describe EpisodePresenter, type: :model do
  let(:episode) { create(:episode, created_at: Time.zone.parse("2012-07-11 21:00")) }
  let(:presenter) { described_class.new(episode) }

  it "formats the created_at" do
    expect(presenter.created_at).to eq("11.07.2012 21:00")
  end

  describe "#transcript?" do
    it "returns true when transcript is present" do
      episode.update!(transcript: "WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nHello")

      expect(presenter.transcript?).to be true
    end

    it "returns false when transcript is blank" do
      expect(presenter.transcript?).to be false
    end
  end
end
