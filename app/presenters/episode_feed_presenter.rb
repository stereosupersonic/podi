require "redcarpet/render_strip"
class EpisodeFeedPresenter < EpisodePresenter
  include ActionView::Helpers::SanitizeHelper

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

    [].tap do |result|
      result << render_markdown_to_html(o.description)
      result << render_markdown_to_html(chapter_list_html) if chapter_marks.present?

      if o.nodes.present?
        result << render_markdown_to_html(show_notes)
      end

      result << stay_in_contact_html
    end.compact.join("<br />").html_safe
  end

  def description_with_show_notes_text
    [].tap do |result|
      result << render_markdown_to_plain_text(o.description)
      result << render_markdown_to_plain_text(chapter_list) if chapter_marks.present?

      if o.nodes.present?
        result << render_markdown_to_plain_text(show_notes)
      end

      result << render_markdown_to_plain_text(stay_in_contact_markdown)
    end.compact.join("\n")
  end

  def chapter_list
    return if o.chapter_marks.blank?
    <<~MARKDOWN.strip
      Kapitelmarken:
      #{Array(sanitized_chapter_marks).join("\n")}
    MARKDOWN
  end

  def chapter_list_html
    return if o.chapter_marks.blank?
    (["Kapitelmarken:"] + Array(sanitized_chapter_marks)).join("<br />")
  end

  def show_notes
    ["### Show Notes", o.nodes.presence].join("\n")
  end

  def sanitized_chapter_marks
    ConvertChaptersToText.call(chapters: o.chapter_marks)
  end

  def stay_in_contact_html
    <<~HTML.strip
      <h2>Kontakt</h2>
      <p>
        <br />
        <b>Schreibt uns!</b>
        <br />
        Schickt uns eure Themenwünsche und euer Feedback.<br />
        <a href='mailto:#{current_setting.email}'>#{current_setting.email}</a>
        <br />
        <br />
        <b>Folgt uns!</b>
        <br />
        Bleibt auf dem Laufenden über zukünftige Folgen
        <br />
        <a href='#{current_setting.twitter_url}'>Twitter</a>
        <br />
        <a href='#{current_setting.instagram_url}'>Instagram</a>
        <br />
        <a href='#{current_setting.facebook_url}'>Facebook</a>
        <br />
        <a href='#{current_setting.youtube_url}'>YouTube</a>
        <br />
      </p>
    HTML
  end

  def stay_in_contact_markdown
    <<~MARKDOWN.strip
      ## Kontakt

      **Schreibt uns!**
      Schickt uns eure Themenwünsche und euer Feedback.
      [#{current_setting.email}](mailto:#{current_setting.email})

      **Folgt uns!**
      Bleibt auf dem Laufenden über zukünftige Folgen
      [Twitter](#{current_setting.twitter_url})
      [Instagram](#{current_setting.instagram_url})
      [Facebook](#{current_setting.facebook_url})
      [YouTube](#{current_setting.youtube_url})
    MARKDOWN
  end

  def pub_date
    # # The date and time when an episode was released. RFC 2822
    o.published_on.to_date.rfc822
  end

  def number
    o.number.to_i
  end

  private

  def render_markdown_to_html(text)
    return "" if text.blank?

    markdown_processor.render(text)
  end

  def render_markdown_to_plain_text(text)
    return "" if text.blank?

    markdown_text_processor.render(text)
  end

  def markdown_processor
    @markdown_processor ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  end

  def markdown_text_processor
    @markdown_text_processor ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown, autolink: true, tables: true)
  end
end
