require "rails_helper"

RSpec.describe "episodes", type: :request do
  describe "GET /episodes.rss" do
    it "generates a feed" do
      FactoryBot.create_list :episode, 2

      get "/episodes.rss"
      # rubocop:disable Layout/LineLength
      expect(response.body.squish).to eq(
        %( <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:atom="http://www.w3.org/2005/Atom/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
          <channel>
            <title>Wartenberger Podcast</title>
            <description>Der Podcast über und um den Markt Wartenberg</description>
            <itunes:image href="https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/logo-itunes.png"/>
            <language>de-de</language>
            <itunes:category text="News">
              <itunes:category text="Politics"/>
            </itunes:category>
            <itunes:explicit>false</itunes:explicit>
            <itunes:author>Michael Deimel</itunes:author>
            <link href="https://wartenberger.de/"/>
            <itunes:owner>
              <itunes:name>Michael Deimel</itunes:name>
              <itunes:email>admin@wartenberger.de</itunes:email>
            </itunes:owner>
            <item>
              <title>Soli Wartenberg 2</title>
              <enclosure url="http://wartenberger.test.com/episodes/002-soli-wartenberg-2.mp3" length="123" type="audio/mpeg"/>
              <guid>http://wartenberger.test.com/episodes/002-soli-wartenberg-2.mp3</guid>
              <pubDate>Mon, 21 Dec 2020 00:00:00 +0000</pubDate>
              <description>we talk about bikes and things</description>
              <itunes:duration>321</itunes:duration>
              <link>http://wartenberger.test.com/episodes/002-soli-wartenberg-2</link>
              <itunes:explicit>false</itunes:explicit>
            </item>
            <item>
              <title>Soli Wartenberg 3</title>
              <enclosure url="http://wartenberger.test.com/episodes/003-soli-wartenberg-3.mp3" length="123" type="audio/mpeg"/>
              <guid>http://wartenberger.test.com/episodes/003-soli-wartenberg-3.mp3</guid>
              <pubDate>Mon, 21 Dec 2020 00:00:00 +0000</pubDate>
              <description>we talk about bikes and things</description>
              <itunes:duration>321</itunes:duration>
              <link>http://wartenberger.test.com/episodes/003-soli-wartenberg-3</link>
              <itunes:explicit>false</itunes:explicit>
            </item>
          </channel>
        </rss>).squish
      )
      # rubocop:enable Layout/LineLength
    end
  end

  describe "GET /episode.mp3" do
    it "increment the download counter" do
      episode = EpisodePresenter.new FactoryBot.create :episode, downloads_count: 0, number: 4, title: :test

      get episode.mp3_url

      expect(response.body).to eq "<html><body>You are being " \
      "<a href=\"https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/004-test.mp3\">redirected</a>.</body></html>"
      expect(episode.reload.downloads_count).to eq 1
    end
  end
end