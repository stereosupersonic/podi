require "rails_helper"

RSpec.describe "episodes", type: :request do
  before { allow(FetchGeoData).to receive(:call).and_return({}) }
  describe "GET /episodes.rss" do
    let!(:setting) { FactoryBot.create(:setting) }

    it "generates a feed" do
      episode1 = FactoryBot.create :episode, number: 1, title: "Soli Wartenberg"

      nodes = <<~MARKDOWN
        * [link](https://test.com)
        * [link2](https://test.com)
      MARKDOWN
      chapter_marks = <<~MARKDOWN
        00:00:00.001  Intro
        00:01:00.001  Begrüßung
        00:04:34.001  Outro
      MARKDOWN
      episode2 = FactoryBot.create :episode, number: 2, title: "Anton Müller",
        nodes: nodes, chapter_marks: chapter_marks

      FactoryBot.create :episode, number: 3, title: "Future", published_on: 1.day.since
      FactoryBot.create :episode, number: 4, title: "inactive", active: false

      # update metadata because active_storage analysers are not running
      episode1.audio.blob.metadata[:duration] = 321
      episode1.audio.blob.save!
      episode2.audio.blob.metadata[:duration] = 321
      episode2.audio.blob.save!

      get "/episodes.rss"

      expected_xml = %(<?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/"
                           xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
                           xmlns:admin="http://webns.net/mvcb/"
                           xmlns:atom="http://www.w3.org/2005/Atom/"
                           xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                           xmlns:content="http://purl.org/rss/1.0/modules/content/"
                          xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
          <channel>
            <title>Wartenberger Podcast</title>
            <description>Der Podcast über und um den Markt Wartenberg</description>
            <itunes:image href="#{setting.logo_url}"/>
            <language>de-de</language>
            <itunes:category text="News">
              <itunes:category text="Politics"/>
            </itunes:category>
            <itunes:explicit>False</itunes:explicit>
            <itunes:author>Michael Deimel, Thomas Rademacher</itunes:author>
            <link>http://wartenberger.test.com</link>
            <itunes:owner>
              <itunes:name>Michael Deimel</itunes:name>
              <itunes:email>admin@wartenberger.de</itunes:email>
            </itunes:owner>
            <itunes:title>Wartenberger Podcast</itunes:title>
            <copyright>Copyright #{Time.current.year} Michael Deimel</copyright>
            <item>
              <title>Anton Müller</title>
              <enclosure url="http://wartenberger.test.com/episodes/002-anton-muller.mp3" length="52632" type="audio/mpeg"/>
              <guid>http://wartenberger.test.com/episodes/002-anton-muller.mp3</guid>
              <pubDate>#{episode2.published_on.to_date.rfc822}</pubDate>
              <description>
                <![CDATA[<p>we talk about bikes and things</p>
                  <br /><p>(00:00:00) Intro<br />(00:01:00) Begrüßung<br />(00:04:34) Outro</p>
                  <br /><h3>Show Notes</h3> <ul>
                  <li><a href="https://test.com">link</a></li> <li><a href="https://test.com">link2</a></li> </ul>
                  <br /><h2>Kontakt</h2> <p> <br /> <b>Schreibt uns!</b>
                  <br /> Schickt uns eure Themenwünsche und euer Feedback.<br />
                  <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br /> <br /> <b>Folgt uns!</b>
                  <br /> Bleibt auf dem Laufenden über zukünftige Folgen <br />
                  <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br />
                  <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br />
                  <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br />
                  <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br /> </p>
                  <p>description</p>]]>
              </description>
              <content:encoded>
                <![CDATA[<p>we talk about bikes and things</p>
                  <br /><p>(00:00:00) Intro<br />(00:01:00) Begrüßung<br />(00:04:34) Outro</p>
                  <br /><h3>Show Notes</h3> <ul>
                  <li><a href="https://test.com">link</a></li>
                  <li><a href="https://test.com">link2</a></li> </ul>
                  <br /><h2>Kontakt</h2> <p> <br /> <b>Schreibt uns!</b>
                  <br /> Schickt uns eure Themenwünsche und euer Feedback.<br />
                  <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br /> <br />
                  <b>Folgt uns!</b> <br /> Bleibt auf dem Laufenden über zukünftige Folgen <br />
                  <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br />
                  <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br />
                  <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br />
                  <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br /> </p>
                  <p>content</p>]]>
              </content:encoded>
              <itunes:summary>we talk about bikes and things (00:00:00) Intro (00:01:00) Begrüßung (00:04:34) Outro
              Show Notes link (https://test.com) link2 (https://test.com) Kontakt Schreibt uns! Schickt uns eure
              Themenwünsche und euer Feedback. admin@wartenberger.de (mailto:admin@wartenberger.de) Folgt uns! Bleibt auf dem
              Laufenden über zukünftige Folgen Twitter (https://twitter.com/WartenbergerPod) Instagram
              (https://www.instagram.com/wartenbergerpodcast) Facebook
              (https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563) YouTube
              (https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg) </itunes:summary>
              <itunes:duration>321</itunes:duration>
              <psc:chapters xmlns:psc="http://podlove.org/simple-chapters" version="1.2">
                <psc:chapter start="00:00:00" title="Intro"/>
                <psc:chapter start="00:01:00" title="Begrüßung"/>
                <psc:chapter start="00:04:34" title="Outro"/>
              </psc:chapters>
              <link>http://wartenberger.test.com/episodes/002-anton-muller</link>
              <itunes:image href="https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/002-anton-muller.jpg"/>
              <itunes:explicit>False</itunes:explicit>
              <itunes:episode>2</itunes:episode>
              <itunes:episodeType>full</itunes:episodeType>
            </item>
            <item>
              <title>Soli Wartenberg</title>
              <enclosure url="http://wartenberger.test.com/episodes/001-soli-wartenberg.mp3" length="52632" type="audio/mpeg"/>
              <guid>http://wartenberger.test.com/episodes/001-soli-wartenberg.mp3</guid>
              <pubDate>#{episode1.published_on.to_date.rfc822}</pubDate>
              <description>
              <![CDATA[<p>we talk about bikes and things</p> <br /><h3>Show Notes</h3> <ul> <li>some nodes</li> </ul> <br /><h2>Kontakt</h2> <p> <br /> <b>Schreibt uns!</b> <br /> Schickt uns eure Themenwünsche und euer Feedback.<br /> <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br /> <br /> <b>Folgt uns!</b> <br /> Bleibt auf dem Laufenden über zukünftige Folgen <br /> <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br /> <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br /> <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br /> <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br /> </p> <p>description</p>]]>
            </description>
            <content:encoded>
              <![CDATA[<p>we talk about bikes and things</p> <br /><h3>Show Notes</h3> <ul> <li>some nodes</li> </ul> <br /><h2>Kontakt</h2> <p> <br /> <b>Schreibt uns!</b> <br /> Schickt uns eure Themenwünsche und euer Feedback.<br /> <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br /> <br /> <b>Folgt uns!</b> <br /> Bleibt auf dem Laufenden über zukünftige Folgen <br /> <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br /> <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br /> <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br /> <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br /> </p> <p>content</p>]]>
            </content:encoded>
              <itunes:summary>we talk about bikes and things Show Notes some nodes Kontakt Schreibt uns! Schickt uns eure
              Themenwünsche und euer Feedback. admin@wartenberger.de (mailto:admin@wartenberger.de) Folgt uns! Bleibt auf dem
              Laufenden über zukünftige Folgen Twitter (https://twitter.com/WartenbergerPod) Instagram
              (https://www.instagram.com/wartenbergerpodcast) Facebook
              (https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563) YouTube
              (https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg) </itunes:summary>
              <itunes:duration>321</itunes:duration>
              <link>http://wartenberger.test.com/episodes/001-soli-wartenberg</link>
              <itunes:image href="https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/001-soli-wartenberg.jpg"/>
              <itunes:explicit>False</itunes:explicit>
              <itunes:episode>1</itunes:episode>
              <itunes:episodeType>full</itunes:episodeType>
            </item>
          </channel>
        </rss>)

      # Debugging
      File.write("response.xml", response.body.squish)
      File.write("expected_xml.xml", expected_xml.squish)
      expect(response.body).to match_xml(expected_xml)

      # remove epsiode from rss feed
      episode2.update! rss_feed: false
      get "/episodes.rss"

      expected_xml = %(<?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/"
                           xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
                           xmlns:admin="http://webns.net/mvcb/"
                           xmlns:atom="http://www.w3.org/2005/Atom/"
                           xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                           xmlns:content="http://purl.org/rss/1.0/modules/content/"
                          xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
          <channel>
            <title>Wartenberger Podcast</title>
            <description>Der Podcast über und um den Markt Wartenberg</description>
            <itunes:image href="#{setting.logo_url}"/>
            <language>de-de</language>
            <itunes:category text="News">
              <itunes:category text="Politics"/>
            </itunes:category>
            <itunes:explicit>False</itunes:explicit>
            <itunes:author>Michael Deimel, Thomas Rademacher</itunes:author>
            <link>http://wartenberger.test.com</link>
            <itunes:owner>
              <itunes:name>Michael Deimel</itunes:name>
              <itunes:email>admin@wartenberger.de</itunes:email>
            </itunes:owner>
            <itunes:title>Wartenberger Podcast</itunes:title>
            <copyright>Copyright #{Time.current.year} Michael Deimel</copyright>
            <item>
              <title>Soli Wartenberg</title>
              <enclosure url="http://wartenberger.test.com/episodes/001-soli-wartenberg.mp3" length="52632" type="audio/mpeg"/>
              <guid>http://wartenberger.test.com/episodes/001-soli-wartenberg.mp3</guid>
              <pubDate>#{episode1.published_on.to_date.rfc822}</pubDate>
              <description>
              <![CDATA[<p>we talk about bikes and things</p> <br /><h3>Show Notes</h3> <ul> <li>some nodes</li> </ul> <br /><h2>Kontakt</h2> <p> <br /> <b>Schreibt uns!</b> <br /> Schickt uns eure Themenwünsche und euer Feedback.<br /> <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br /> <br /> <b>Folgt uns!</b> <br /> Bleibt auf dem Laufenden über zukünftige Folgen <br /> <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br /> <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br /> <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br /> <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br /> </p> <p>description</p>]]>
            </description>
            <content:encoded>
              <![CDATA[<p>we talk about bikes and things</p> <br /><h3>Show Notes</h3> <ul> <li>some nodes</li> </ul> <br /><h2>Kontakt</h2> <p> <br /> <b>Schreibt uns!</b> <br /> Schickt uns eure Themenwünsche und euer Feedback.<br /> <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br /> <br /> <b>Folgt uns!</b> <br /> Bleibt auf dem Laufenden über zukünftige Folgen <br /> <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br /> <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br /> <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br /> <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br /> </p> <p>content</p>]]>
            </content:encoded>
              <itunes:summary>we talk about bikes and things Show Notes some nodes Kontakt Schreibt uns! Schickt uns eure
              Themenwünsche und euer Feedback. admin@wartenberger.de (mailto:admin@wartenberger.de) Folgt uns! Bleibt auf dem
              Laufenden über zukünftige Folgen Twitter (https://twitter.com/WartenbergerPod) Instagram
              (https://www.instagram.com/wartenbergerpodcast) Facebook
              (https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563) YouTube
              (https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg) </itunes:summary>
              <itunes:duration>321</itunes:duration>
              <link>http://wartenberger.test.com/episodes/001-soli-wartenberg</link>
              <itunes:image href="https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/001-soli-wartenberg.jpg"/>
              <itunes:explicit>False</itunes:explicit>
              <itunes:episode>1</itunes:episode>
              <itunes:episodeType>full</itunes:episodeType>
            </item>
          </channel>
        </rss>)

      File.write("response.xml", response.body.squish)
      File.write("expected_xml.xml", expected_xml.squish)
      expect(response.body).to match_xml(expected_xml)
    end
  end

  describe "GET /episode.mp3" do
    let(:episode) { EpisodePresenter.new FactoryBot.create :episode, downloads_count: 1, number: 4, title: :test }
    describe "download counter" do
      it "increment" do
        get episode.mp3_url
        perform_enqueued_jobs_now!

        expect(response.body).to match(%r{<html><body>You are being <a href=.*>redirected</a>\.</body></html>})
        expect(response.body).to match(%r{http://wartenberger\.test\.com/.*/test-001\.mp3})
        expect(episode.reload.downloads_count).to eq 2
      end

      it "dont increment with notracking flag" do
        get episode.mp3_url(notracking: true)
        perform_enqueued_jobs_now!

        expect(response.body).to match(%r{<html><body>You are being <a href=.*>redirected</a>\.</body></html>})
        expect(response.body).to match(%r{http://wartenberger\.test\.com/.*/test-001\.mp3})
        expect(episode.reload.downloads_count).to eq 1
      end
    end

    describe "log data" do
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
      let(:cache) { Rails.cache }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        Rails.cache.clear
      end

      it "enquese the event job" do
        expect {
          get episode.mp3_url
        }.to enqueue_job(Mp3EventJob)
      end

      it "logs valid data" do
        ua = "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.17 Safari/537.36"
        headers = {"HTTP_USER_AGENT" => ua}
        expect(FetchGeoData).to receive(:call).with(ip_address: "127.0.0.1").and_return FactoryBot.build(:event).geo_data
        downloaded_at = Time.current
        travel_to downloaded_at do
          get episode.mp3_url, params: {}, headers: headers
          perform_enqueued_jobs_now!
        end
        event = Event.last
        expect(event).to_not be_nil
        expect(event.episode).to eq episode.reload
        expect(event.downloaded_at).to be_within(1.second).of downloaded_at
        expect(event.data.symbolize_keys).to include(
          user_agent: /Mozilla\/5\.0/,
          remote_ip: "127.0.0.1",
          uuid: a_kind_of(String),
          client_name: "Chrome",
          client_full_version: "30.0.1599.17",
          client_os_name: "Windows",
          client_os_full_version: "8",
          client_device_name: nil,
          client_device_type: "desktop"
        )
        expect(event.geo_data.symbolize_keys).to include(
          country: "Germany",
          county: "Bavaria",
          iso_code: "DE",
          city: "Moosburg",
          plz: "85368",
          latitude: "48.4668",
          longitude: "11.9476",
          accuracy_radiu: 10,
          isp: "Deutsche Telekom AG"
        )
      end
      it "logs valid data without a user_agent " do
        get episode.mp3_url
        perform_enqueued_jobs_now!

        event = Event.last
        expect(event).to_not be_nil
        expect(event.episode).to eq episode.reload
      end

      it "don't logs data when client downloads within 2 minutes" do
        Rails.configuration.cache_store = :memory_store
        episode2 = EpisodePresenter.new FactoryBot.create :episode, number: 2, title: "Anton Müller", downloads_count: 0
        episode.update downloads_count: 0

        expect do
          get episode.mp3_url, params: {}, env: {"REMOTE_ADDR": "192.168.1.2"}
          sleep 1
          get episode.mp3_url, params: {}, env: {"REMOTE_ADDR": "192.168.1.2"}
          get episode2.mp3_url, params: {}, env: {"REMOTE_ADDR": "192.168.1.2"}
          get episode.mp3_url, params: {}, env: {"REMOTE_ADDR": "192.168.1.2"}
          get episode.mp3_url, params: {}, env: {"REMOTE_ADDR": "192.168.1.1"}
          travel_to 121.seconds.from_now do
            get episode.mp3_url, params: {}, env: {"REMOTE_ADDR": "192.168.1.2"}
          end
        end.to have_enqueued_job(Mp3EventJob).exactly(4)
        perform_enqueued_jobs_now!

        expect(episode.reload.downloads_count).to eq 3
        expect(episode2.reload.downloads_count).to eq 1
      end
    end
  end
end
