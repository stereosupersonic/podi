require "rails_helper"

RSpec.describe PodloveWebplayerConfigBuilder do
  let(:episode) { EpisodePresenter.new(create(:episode)) }

  describe "#episode_config" do
    it "builds the episode configuration" do
      config = described_class.new(episode).episode_config

      expect(config).to eq(
        {
          poster: episode.artwork_url,
          duration: "00:00:03.000",
          audio: [
            {
              url: episode.mp3_url,
              mimeType: "audio/mpeg"
            }
          ],
          chapters: []
        }
      )
    end

    it "formats duration as HH:MM:SS.000" do
      config = described_class.new(episode).episode_config

      expect(config[:duration]).to eq("00:00:03.000")
    end

    it "sets duration to nil when episode has no audio" do
      allow(episode).to receive(:duration).and_return(nil)

      config = described_class.new(episode).episode_config

      expect(config[:duration]).to be_nil
    end

    it "includes parsed chapter marks" do
      episode.chapter_marks = %(
       00:00:01 Intro
       00:00:41 Begrüßung der Mannschaft
       00:01:30 Vorstellung
      )
      episode.save!

      config = described_class.new(episode).episode_config

      expect(config[:chapters]).to eq(
        [
          { start: "00:00:01", title: "Intro" },
          { start: "00:00:41", title: "Begrüßung der Mannschaft" },
          { start: "00:01:30", title: "Vorstellung" }
        ]
      )
    end
  end

  describe "#player_config" do
    it "builds the player configuration with theme" do
      config = described_class.new(episode).player_config

      expect(config).to eq(
        {
          version: 5,
          activeTab: "chapters",
          theme: {
            tokens: {
              brand: "#5c626e",
              brandDark: "#45494f",
              brandDarkest: "#25262a",
              brandLightest: "#edf0f5",
              shadeDark: "#25262a",
              shadeBase: "#5c626e",
              contrast: "#25262a",
              alt: "#f8f9fa"
            },
            fonts: {
              ci: {
                family: [ "system-ui", "-apple-system", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif" ]
              },
              regular: {
                family: [ "system-ui", "-apple-system", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif" ]
              },
              bold: {
                family: [ "system-ui", "-apple-system", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif" ],
                weight: 700
              }
            }
          }
        }
      )
    end
  end
end
