require "rails_helper"

RSpec.describe PodigeeWebplayerConfigBuilder do
  let(:episode) { EpisodePresenter.new(FactoryBot.create(:episode)) }

  it "builds a valid config as json" do
    json_config = described_class.new(episode).to_json

    expect(JSON.parse(json_config)).to eq(
      {
        "episode" =>
        {
          "chaptermarks" => nil,
          "coverUrl" => nil,
          "description" => nil,
          "media" => {"mp3" => "http://wartenberger.test.com/episodes/#{episode.slug}.mp3"},
          "subtitle" => nil,
          "title" => nil,
          "url" => "http://wartenberger.test.com/episodes/#{episode.slug}"
        },
        "extensions" =>
          {
            "ChapterMarks" => {},
            "SubscribeBar" => {}
          },
        "options" =>
          {
            "startPanel" => "ChapterMarks",
            "theme" => "default"
          }
      }
    )
  end

  it "builds a valid chapter marks config" do
    episode.chapter_marks = %(
     00:00:01 Intro
     00:00:41 Begrüßung der Mannschaft
     00:01:30 Vorstellung
    )
    episode.save!

    json_config = described_class.new(episode).to_json
    hash_config = JSON.parse(json_config)

    expect(hash_config["episode"]["chaptermarks"]).to eq(
      [{"start" => "00:00:01", "title" => "Intro"},
        {"start" => "00:00:41", "title" => "Begrüßung der Mannschaft"},
        {"start" => "00:01:30", "title" => "Vorstellung"}]
    )
  end
end
