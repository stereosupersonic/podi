require "rails_helper"

RSpec.describe EpisodeCreator do
  let(:attributes) do
    {
      title: "Neue Folge",
      description: "description",
      nodes: "* notes",
      published_on: Date.current,
      audio: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/test-001.mp3"), "audio/mpeg")
    }
  end

  context "without a number" do
    it "saves the episode with the next number and a slug", :aggregate_failures do
      create(:episode, number: 4)

      episode = described_class.call(episode_attributes: attributes)

      expect(episode).to be_persisted
      expect(episode.number).to eq(5)
      expect(episode.slug).to eq("005-neue-folge")
    end
  end

  context "with a number" do
    it "keeps the given number", :aggregate_failures do
      episode = described_class.call(episode_attributes: attributes.merge(number: 12))

      expect(episode.number).to eq(12)
      expect(episode.slug).to eq("012-neue-folge")
    end
  end

  context "with invalid attributes" do
    it "returns the unsaved episode with errors", :aggregate_failures do
      episode = described_class.call(episode_attributes: attributes.merge(title: ""))

      expect(episode).not_to be_persisted
      expect(episode.errors[:title]).to include("can't be blank")
    end
  end
end
