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
  xml.description { xml.cdata!(episode.description_with_show_notes_html) }
  xml.tag!("content:encoded") { xml.cdata!(episode.description_with_show_notes_html) }
  # The duration of an episode.
  xml.tag! "itunes:duration", episode.duration

  # An episode link URL.
  xml.link episode.episonde_url

  # The episode artwork.
  # TODO
  xml.tag! "itunes:image", href: episode.artwork_url

  # The episode parental advisory information.
  xml.tag! "itunes:explicit", false
  xml.tag! "itunes:episode", episode.number
  xml.tag! "itunes:episodeType", "full"
end
