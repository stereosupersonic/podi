xml.item do
  # An episode title
  xml.title episode.title

  # The episode content, file size, and file type information.
  xml.enclosure(url: episode.mp3_url, length: episode.length, type: episode.audio_type)

  # The episode’s globally unique identifier (GUID)
  xml.guid episode.guid

  # The date and time when an episode was released.  RFC 2822
  xml.pubDate episode.pub_date

  # An episode description. max 4000
  xml.description { xml.cdata!(episode.description_with_show_notes_html + " <p>description</p>".html_safe) }
  xml.tag!("content:encoded") { xml.cdata!(episode.description_with_show_notes_html + " <p>content</p>".html_safe) }
  xml.tag!("itunes:summary", episode.description_with_show_notes_text)
  # The duration of an episode.
  xml.tag! "itunes:duration", episode.duration

  # podlover chapter marks
  # https://podlove.org/simple-chapters/
  if episode.chapter_objects.any?
    xml.tag!("psc:chapters", "xmlns:psc" => "http://podlove.org/simple-chapters", :version => "1.2") do
      episode.chapter_objects.each do |chapter|
        xml.tag!("psc:chapter", start: chapter.start, title: chapter.title)
      end
    end
  end
  # An episode link URL.
  xml.link episode.episonde_url

  # The episode artwork.
  # TODO
  xml.tag! "itunes:image", href: episode.artwork_url

  # The episode parental advisory information.
  xml.tag! "itunes:explicit", "False"
  xml.tag! "itunes:episode", episode.number
  xml.tag! "itunes:episodeType", "full"
end
