class EpisodeFeedPresenter < EpisodePresenter
  delegate :author, to: :current_setting

  def duration
    # Different duration formats are accepted however
    # it is recommended to convert the length of the episode into seconds.
    o.duration
  end

  def artwork_url
    super(size: 1400)
  end

  def audio_type
    #  The type attribute provides the correct category for the type of file you are using.
    # The type values for the supported file formats are:
    # audio/x-m4a, audio/mpeg, video/quicktime, video/mp4, video/x-m4v, and application/pdf.
    "audio/mpeg"
  end

  def length
    # The length attribute is the file size in bytes.
    # You can find this information in the properties of your podcast file
    o.audio_size
  end

  def guid
    # The episode’s globally unique identifier (GUID).
    # It is very important that each episode have a unique GUID and that it never changes, even if an episode’s metadata,
    # like title or enclosure URL, do change.
    # Globally unique identifiers (GUID) are case-sensitive strings.
    # If a GUID is not provided an episode’s enclosure URL will be used instead.
    # If a GUID is not provided, make sure that an episode’s enclosure URL is unique and never changes.
    # Failing to comply with these guidelines may result in duplicate episodes being shown to listeners,
    # inaccurate data in Podcast Analytics,
    # and can cause issues with your podcasts’s listing and chart placement in Apple Podcasts.
    mp3_url
  end

  def description_with_show_notes_html
    # An episode description.
    # description is text containing one or more sentences describing your episode to potential listeners.
    # You can specify up to 4000 characters.
    # You can use rich text formatting and some HTML (<p>, <ol>, <ul>, <li>, <a>) if wrapped in the <CDATA> tag.
    #
    # To include links in your description or rich HTML, adhere to the following technical guidelines:
    # enclose all portions of your XML that contain embedded HTML in a CDATA section to prevent formatting issues,
    # and to ensure proper
    #  link functionality. For example:
    #
    #   <![CDATA[
    #     <a href="http://www.apple.com">Apple</a>
    #   ]]>
    [
      render_markdown(o.description),
      render_markdown("### Show Notes"),
      render_markdown(o.nodes.presence || "no notes available"),
      stay_in_contact_html.html_safe
    ].join("<br>").html_safe
  end

  def stay_in_contact_html
    <<~HTML.strip
      <br>
      <h2>Kontakt</h2>
      <p>
        <br>
        <b>Schreibt uns!</b>
        <br>
        Schickt uns eure Themenwünsche und euer Feedback.<br>
        <a href='mailto:#{current_setting.email}'>#{current_setting.email}</a>
        <br>
        <br>
        <b>Folgt uns!</b>
        <br>
        Bleibt auf dem Laufenden über zukünftige Folgen
        <br>
        <a href='#{current_setting.twitter_url}'>Twitter</a>
        <br>
        <a href='#{current_setting.instagram_url}'>Instagram</a>
        <br>
        <a href='#{current_setting.facebook_url}'>Facebook</a>
        <br>
        <a href='#{current_setting.youtube_url}'>YouTube</a>
        <br>
      </p>
    HTML
  end

  def pub_date
    # # The date and time when an episode was released. RFC 2822
    o.published_on.to_date.rfc822
  end

  private

  def render_markdown(text)
    return "" if text.blank?

    markdown_processor.render(text.to_s).html_safe
  end

  def markdown_processor
    @markdown_processor ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  end
end
