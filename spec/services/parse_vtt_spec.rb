require "rails_helper"

RSpec.describe ParseVtt do
  describe "#call" do
    it "parses VTT content into transcript segments" do
      vtt = <<~VTT
        WEBVTT

        00:00:00.017 --> 00:00:07.597
        Servus und herzlich willkommen zu einer neuen Podcast-Episode.

        00:00:08.277 --> 00:00:15.617
        Heute reden wir mit dem Ortsverband der SPD.
      VTT

      result = described_class.call(vtt)

      expect(result).to eq([
        {
          start: "00:00:00.017",
          start_ms: 17,
          end: "00:00:07.597",
          end_ms: 7597,
          text: "Servus und herzlich willkommen zu einer neuen Podcast-Episode."
        },
        {
          start: "00:00:08.277",
          start_ms: 8277,
          end: "00:00:15.617",
          end_ms: 15617,
          text: "Heute reden wir mit dem Ortsverband der SPD."
        }
      ])
    end

    it "returns an empty array for blank input" do
      expect(described_class.call("")).to eq([])
      expect(described_class.call(nil)).to eq([])
    end

    it "skips the WEBVTT header and blank lines" do
      vtt = <<~VTT
        WEBVTT

        00:00:01.000 --> 00:00:02.000
        Hello
      VTT

      result = described_class.call(vtt)

      expect(result.size).to eq(1)
      expect(result.first[:text]).to eq("Hello")
    end

    it "handles multi-line text within a single cue" do
      vtt = <<~VTT
        WEBVTT

        00:00:01.000 --> 00:00:05.000
        First line
        Second line
      VTT

      result = described_class.call(vtt)

      expect(result.size).to eq(1)
      expect(result.first[:text]).to eq("First line Second line")
    end
  end
end
