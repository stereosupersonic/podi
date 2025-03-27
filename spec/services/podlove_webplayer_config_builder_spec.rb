require "rails_helper"

RSpec.describe PodloveWebplayerConfigBuilder do
  let(:episode) { create(:episode, chapter_marks: "00:00:00 Intro\n00:01:30 Topic 1") }
  let(:builder) { PodloveWebplayerConfigBuilder.new(episode) }
  let(:config) { JSON.parse(builder.to_json) }

  describe "#to_json" do
    it "builds the proper config" do
      expect(config["version"]).to eq(5)
      expect(config["title"]).to eq(episode.title)
      expect(config["episode"]["number"]).to eq(episode.number)
      expect(config["audio"].first["url"]).to eq(episode.mp3_url)
      expect(config["duration"]).to eq(episode.duration.to_s)
    end

    it "includes chapter marks" do
      expect(config["chapters"].length).to eq(2)
      expect(config["chapters"].first["start"]).to eq("00:00:00")
      expect(config["chapters"].first["title"]).to eq("Intro")
      expect(config["chapters"].last["start"]).to eq("00:01:30")
      expect(config["chapters"].last["title"]).to eq("Topic 1")
    end

    it "handles empty chapter marks" do
      episode.chapter_marks = nil
      expect(config["chapters"]).to eq([])
    end
  end
end
