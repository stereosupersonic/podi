require "rails_helper"

RSpec.describe "episodes", type: :request do
  describe "GET /episodes.rss" do
    let!(:setting) { FactoryBot.create(:setting) }

    it "generates a feed" do
      episode1 = FactoryBot.create :episode, number: 1, title: "Soli Wartenberg"
      episode2 = FactoryBot.create :episode, number: 2, title: "Anton Müller",
        nodes: <<~MARKDOWN
          * [link](https://test.com)
          * [link2](https://test.com)
        MARKDOWN
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
            <itunes:explicit>false</itunes:explicit>
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
                <![CDATA[<p>we talk about bikes and things</p> <br><h3>Show Notes</h3> <br><ul>
                  <li><a href="https://test.com">link</a></li> <li><a href="https://test.com">link2</a></li> </ul>
                  <br><br> <h2>Kontakt</h2> <p> <br> <b>Schreibt uns!</b>
                  <br> Schickt uns eure Themenwünsche und euer Feedback.<br>
                  <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br> <br> <b>Folgt uns!</b>
                  <br> Bleibt auf dem Laufenden über zukünftige Folgen <br>
                  <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br>
                  <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br>
                  <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br>
                  <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br> </p>]]>
              </description>
              <content:encoded>
                <![CDATA[<p>we talk about bikes and things</p> <br><h3>Show Notes</h3> <br><ul>
                  <li><a href="https://test.com">link</a></li>
                  <li><a href="https://test.com">link2</a></li> </ul>
                  <br><br> <h2>Kontakt</h2> <p> <br> <b>Schreibt uns!</b>
                  <br> Schickt uns eure Themenwünsche und euer Feedback.<br>
                  <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br> <br>
                  <b>Folgt uns!</b> <br> Bleibt auf dem Laufenden über zukünftige Folgen <br>
                  <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br>
                  <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br>
                  <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br>
                  <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br> </p>]]>
              </content:encoded>
              <itunes:duration>321</itunes:duration>
              <link>http://wartenberger.test.com/episodes/002-anton-muller</link>
              <itunes:image href="https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/002-anton-muller.jpg"/>
              <itunes:explicit>false</itunes:explicit>
            </item>
            <item>
              <title>Soli Wartenberg</title>
              <enclosure url="http://wartenberger.test.com/episodes/001-soli-wartenberg.mp3" length="52632" type="audio/mpeg"/>
              <guid>http://wartenberger.test.com/episodes/001-soli-wartenberg.mp3</guid>
              <pubDate>#{episode1.published_on.to_date.rfc822}</pubDate>
              <description>
                <![CDATA[<p>we talk about bikes and things</p> <br><h3>Show Notes</h3>
                  <br><ul> <li>some nodes</li> </ul> <br><br> <h2>Kontakt</h2> <p> <br>
                  <b>Schreibt uns!</b> <br> Schickt uns eure Themenwünsche und euer Feedback.<br>
                  <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br> <br>
                  <b>Folgt uns!</b> <br> Bleibt auf dem Laufenden über zukünftige Folgen <br>
                  <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br>
                  <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br>
                  <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br>
                  <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br> </p>]]>
              </description>
              <content:encoded>
              <![CDATA[<p>we talk about bikes and things</p> <br><h3>Show Notes</h3> <br><ul> <li>some nodes</li> </ul> <br><br>
                  <h2>Kontakt</h2> <p> <br> <b>Schreibt uns!</b> <br> Schickt uns eure Themenwünsche und euer Feedback.<br>
                  <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a> <br> <br> <b>Folgt uns!</b> <br>
                  Bleibt auf dem Laufenden über zukünftige Folgen <br>
                  <a href='https://twitter.com/WartenbergerPod'>Twitter</a> <br>
                  <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a> <br>
                  <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a> <br>
                  <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a> <br> </p>]]>
              </content:encoded>
              <itunes:duration>321</itunes:duration>
              <link>http://wartenberger.test.com/episodes/001-soli-wartenberg</link>
              <itunes:image href="https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/001-soli-wartenberg.jpg"/>
              <itunes:explicit>false</itunes:explicit>
            </item>
          </channel>
        </rss>)

      # Debugging
      File.write("response.xml", response.body.squish)
      File.write("expected_xml.xml", expected_xml.squish)
      expect(response.body.squish).to eq(expected_xml.squish)
    end
  end

  describe "GET /episode.mp3" do
    let(:episode) { EpisodePresenter.new FactoryBot.create :episode, downloads_count: 1, number: 4, title: :test }
    describe "download counter" do
      it "increment" do
        get episode.mp3_url

        expect(response.body).to match(%r{<html><body>You are being <a href=.*>redirected</a>\.</body></html>})
        expect(response.body).to match(%r{http://wartenberger\.test\.com/.*/test-001\.mp3})
        expect(episode.reload.downloads_count).to eq 2
      end

      it "dont increment with notracking flag" do
        get episode.mp3_url(notracking: true)

        expect(response.body).to match(%r{<html><body>You are being <a href=.*>redirected</a>\.</body></html>})
        expect(response.body).to match(%r{http://wartenberger\.test\.com/.*/test-001\.mp3})
        expect(episode.reload.downloads_count).to eq 1
      end
    end

    describe "log data" do
      it "enquese the event job" do
        expect {
          get episode.mp3_url
        }.to enqueue_job(Mp3EventJob)
      end

      it "logs valid data" do
        ua = "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.17 Safari/537.36"
        headers = {"HTTP_USER_AGENT" => ua}

        get episode.mp3_url, params: {}, headers: headers
        perform_enqueued_jobs_now!

        event = Event.last
        expect(event).to_not be_nil
        expect(event.episode).to eq episode.reload
        expect(event.media_type).to eq "Chrome"
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
      end
      it "logs valid data without a user_agent " do
        get episode.mp3_url
        perform_enqueued_jobs_now!

        event = Event.last
        expect(event).to_not be_nil
        expect(event.episode).to eq episode.reload
        expect(event.media_type).to be_nil
      end
    end
  end
end
