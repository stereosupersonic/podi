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
require "rails_helper"

RSpec.describe Episode, type: :model do
  let!(:setting) { create(:setting) }

  it "has a valid factory" do
    episode = build(:episode)

    expect(episode).to be_valid
    assert episode.save!
  end

  it "is inactive by default" do
    expect(described_class.new.active).to be(false)
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

  describe "audio validation" do
    context "with an mp3" do
      it "is valid" do
        expect(build(:episode)).to be_valid
      end
    end

    context "with a non-mp3 file declared as audio/mpeg" do
      it "is invalid", :aggregate_failures do
        image = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/001-vorstellung.jpg"), "audio/mpeg")
        episode = build(:episode, audio: image)

        expect(episode).not_to be_valid
        expect(episode.errors[:audio]).to include("must be an MP3 file (audio/mpeg)")
      end
    end
  end

  describe "image validation" do
    def upload(name, type)
      Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures", name), type)
    end

    context "with a square image of 1500 px" do
      it "is valid" do
        expect(build(:episode, image: upload("001-vorstellung.jpg", "image/jpeg"))).to be_valid
      end
    end

    context "with a square image at the smallest allowed size" do
      it "is valid" do
        expect(build(:episode, image: upload("image-1400x1400.png", "image/png"))).to be_valid
      end
    end

    context "with a square image at the largest allowed size" do
      it "is valid" do
        expect(build(:episode, image: upload("image-3000x3000.png", "image/png"))).to be_valid
      end
    end

    context "with an image that is not square" do
      it "is invalid", :aggregate_failures do
        episode = build(:episode, image: upload("image-1400x1120.png", "image/png"))

        expect(episode).not_to be_valid
        expect(episode.errors[:image]).to eq([ "must be square (1:1), this image is 1400×1120 px" ])
      end
    end

    context "with a square image smaller than 1400 px" do
      it "is invalid", :aggregate_failures do
        episode = build(:episode, image: upload("image-600x600.png", "image/png"))

        expect(episode).not_to be_valid
        expect(episode.errors[:image]).to eq([ "must be 1400 to 3000 px wide, this image is 600×600 px" ])
      end
    end

    context "with a square image larger than 3000 px" do
      it "is invalid", :aggregate_failures do
        episode = build(:episode, image: upload("image-3200x3200.png", "image/png"))

        expect(episode).not_to be_valid
        expect(episode.errors[:image]).to eq([ "must be 1400 to 3000 px wide, this image is 3200×3200 px" ])
      end
    end

    context "with an image file whose dimensions cannot be read" do
      it "is invalid", :aggregate_failures do
        episode = build(:episode, image: upload("image-unreadable.png", "image/png"))

        expect(episode).not_to be_valid
        expect(episode.errors[:image]).to eq([ "dimensions could not be read" ])
      end
    end

    context "with a file that is not an image" do
      it "only reports the file type", :aggregate_failures do
        episode = build(:episode, image: upload("test-001.mp3", "audio/mpeg"))

        expect(episode).not_to be_valid
        expect(episode.errors[:image]).to eq([ "type must be one of: image/jpeg, image/png, image/webp" ])
      end
    end
  end

  describe "feed description size" do
    context "with a short description" do
      it "is valid" do
        expect(build(:episode)).to be_valid
      end
    end

    context "with a description over Apple's limit" do
      it "names the size and the excess", :aggregate_failures do
        episode = build(:episode, description: "a" * 4000)

        expect(episode).not_to be_valid
        expect(episode.errors[:description].first)
          .to match(/\Amakes the RSS feed description \d+ bytes, \d+ more than Apple allows \(4000\)/)
      end
    end

    context "with umlauts under 4000 characters but over 4000 bytes" do
      it "is invalid" do
        expect(build(:episode, description: "ü" * 1900)).not_to be_valid
      end
    end
  end

  describe "link validation" do
    context "with full and mail links" do
      it "is valid" do
        episode = build(:episode, description: "[Museum](https://www.dhm.de/lemo/) and https://test.com",
                                  nodes: "* [Mail](mailto:info@wartenberger.de)")

        expect(episode).to be_valid
      end
    end

    context "with a link to another episode without the domain" do
      it "is invalid", :aggregate_failures do
        episode = build(:episode, description: "[Episode 25](025-maria-und-mathias-obermeier-zeitzeugen)")

        expect(episode).not_to be_valid
        expect(episode.errors[:description])
          .to eq([ "contains links without https://: 025-maria-und-mathias-obermeier-zeitzeugen" ])
      end
    end

    context "with a domain without https:// in the show notes" do
      it "is invalid", :aggregate_failures do
        episode = build(:episode, nodes: "* [Lebendiges Museum Online](dhm.de/lemo/)")

        expect(episode).not_to be_valid
        expect(episode.errors[:nodes]).to eq([ "contains links without https://: dhm.de/lemo/" ])
      end
    end

    context "with a relative link in raw HTML" do
      it "is invalid" do
        episode = build(:episode, description: %(<a href="/episodes/001">Episode 1</a>))

        expect(episode).not_to be_valid
      end
    end
  end

  describe ".next_number" do
    it "is 1 when there are no episodes" do
      expect(described_class.next_number).to eq(1)
    end

    it "is one more than the highest number" do
      create(:episode, number: 7)
      create(:episode, number: 3)

      expect(described_class.next_number).to eq(8)
    end
  end

  describe ".all_tags" do
    it "lists every tag once, sorted" do
      create(:episode, tags: %w[Musik Interview])
      create(:episode, tags: %w[Geschichte Musik], active: false)

      expect(described_class.all_tags).to eq(%w[Geschichte Interview Musik])
    end

    it "is empty without tags" do
      create(:episode)

      expect(described_class.all_tags).to eq([])
    end
  end

  describe "#title" do
    it "strips surrounding whitespace" do
      expect(described_class.new(title: " Kiosk am Thenner ").title).to eq("Kiosk am Thenner")
    end
  end

  describe "#build_slug" do
    it "combines the zero-padded number and the title" do
      episode = described_class.new(number: 42, title: "Über den Markt")

      expect(episode.build_slug).to eq("042-ueber-den-markt")
    end

    it "is nil without a title" do
      expect(described_class.new(number: 42).build_slug).to be_nil
    end
  end

  describe ".search" do
    it "finds episodes by title" do
      episode = create(:episode, title: "Fahrrad Geschichte", number: 1)
      create(:episode, title: "Soli Wartenberg", number: 2)

      expect(described_class.search("Fahrrad")).to eq([ episode ])
    end

    it "finds episodes by description" do
      episode = create(:episode, title: "Episode One", number: 1, description: "About cycling")
      create(:episode, title: "Episode Two", number: 2, description: "About cooking")

      expect(described_class.search("cycling")).to eq([ episode ])
    end

    it "finds episodes by tag" do
      episode = create(:episode, title: "Episode One", number: 1, tags: [ "Interview", "Technik" ])
      create(:episode, title: "Episode Two", number: 2, tags: [ "Geschichte" ])

      expect(described_class.search("Interview")).to eq([ episode ])
    end

    it "is case-insensitive" do
      episode = create(:episode, title: "Fahrrad Geschichte", number: 1)

      expect(described_class.search("fahrrad")).to eq([ episode ])
    end

    it "returns none for blank query" do
      create(:episode, number: 1)

      expect(described_class.search("")).to be_empty
      expect(described_class.search(nil)).to be_empty
    end
  end

  describe "#tag_list" do
    it "returns tags as comma-separated string" do
      episode = build(:episode, tags: [ "Interview", "Geschichte" ])

      expect(episode.tag_list).to eq("Interview, Geschichte")
    end

    it "returns empty string when no tags" do
      episode = build(:episode, tags: [])

      expect(episode.tag_list).to eq("")
    end
  end

  describe "#tag_list=" do
    it "splits comma-separated string into tags array" do
      episode = build(:episode)
      episode.tag_list = "Interview, Geschichte, Technik"

      expect(episode.tags).to eq([ "Interview", "Geschichte", "Technik" ])
    end

    it "strips whitespace from tags" do
      episode = build(:episode)
      episode.tag_list = "  Interview ,  Geschichte  "

      expect(episode.tags).to eq([ "Interview", "Geschichte" ])
    end

    it "rejects blank tags" do
      episode = build(:episode)
      episode.tag_list = "Interview,,, Geschichte,"

      expect(episode.tags).to eq([ "Interview", "Geschichte" ])
    end

    it "handles nil" do
      episode = build(:episode)
      episode.tag_list = nil

      expect(episode.tags).to eq([])
    end
  end
end
