class EpisodePresenter < ApplicationPresenter
  delegate :file_size, to: :o

  def published?
    o.active? && !o.published_on.future?
  end

  def number
    o.number.to_s.rjust(3, "0")
  end

  def published_on
    h.format_date o.published_on
  end

  def published_on_iso8601
    o.published_on.iso8601
  end

  def duration_iso8601
    # ISO 8601 Duration format ([hh]:[mm]:[ss].[sss]), capable of add ing milliseconds, see https://en.wikipedia.org/wiki/ISO_8601
    Time.at(o.file_duration).utc.strftime("%H:%M:%S.%3N")
  end

  def artwork_url
    # You should use this tag when you have a high quality, episode-specific image you would like listeners to see.
    # Specify your episode artwork using the <a href> attribute in the <itunes:image> tag.
    # Depending on their device, listeners see your episode artwork in varying sizes.
    # Therefore, make sure your design is effective at both its original size and at thumbnail size.
    # You should include a title, brand, or source name as part of your episode artwork.
    # To avoid technical issues when you update your episode artwork, be sure to:
    # Change the artwork file name and URL at the same time
    # Verify the web server hosting your artwork allows HTTP head requests
    # Artwork must be a minimum size of 1400 x 1400 pixels and a maximum size of 3000 x 3000 pixels,
    # in JPEG or PNG format, 72 dpi, with appropriate file extensions (.jpg, .png), and in the RGB colorspace.
    # These requirements are different from the standard RSS image tag specifications.
    # Make sure the file type in the URL matches the actual file type of the image file.d
    o.artwork_url.presence || current_setting.default_episode_artwork_url
  end

  def mp3_url
    Rails.application.routes.url_helpers.episode_url(o, format: :mp3)
  end

  def episonde_url
    # This is used when an episode has a corresponding webpage. For example:
    Rails.application.routes.url_helpers.episode_url(o)
  end
end
