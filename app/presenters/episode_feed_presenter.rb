require "redcarpet/render_strip"
class EpisodeFeedPresenter < EpisodePresenter
  include ActionView::Helpers::SanitizeHelper

  delegate :author, to: :current_setting

  def artwork_url
    super(size: 1400)
  end

  def audio_type
    "audio/mpeg"
  end

  # File size in bytes
  def length
    o.audio_size
  end

  # Must never change, or podcast apps show the episode twice.
  def guid
    mp3_url
  end

  # Apple allows up to 4000 characters and some HTML (<p>, <ol>, <ul>, <li>, <a>), wrapped in CDATA.
  def description_with_show_notes_html
    [].tap do |result|
      result << render_markdown_to_html(o.description)
      result << render_markdown_to_html(chapter_list_html) if chapter_marks.present?

      result << render_markdown_to_html(show_notes) if o.nodes.present?

      result << stay_in_contact_html
    end.join("<br />").html_safe
  end

  # Apple allows up to 4000 bytes, and umlauts take two bytes each.
  def description_with_show_notes_text
    [].tap do |result|
      result << render_markdown_to_plain_text(o.description)
      result << render_markdown_to_plain_text(chapter_list) if chapter_marks.present?

      result << render_markdown_to_plain_text(show_notes) if o.nodes.present?

      result << render_markdown_to_plain_text(stay_in_contact_markdown)
    end.join("\n").truncate_bytes(4000)
  end

  def chapter_list
    sanitized_chapter_marks.join("\n")
  end

  def chapter_list_html
    sanitized_chapter_marks.join("<br />")
  end

  def show_notes
    [ "### Show Notes", o.nodes.presence ].join("\n")
  end

  def sanitized_chapter_marks
    @sanitized_chapter_marks ||= ConvertChaptersToText.call(chapters: o.chapter_marks)
  end

  def chapter_objects
    @chapter_objects ||= ConvertChapters.call(chapters: o.chapter_marks)
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
    o.published_on.to_date.rfc822
  end

  def number
    o.number.to_i
  end

  private

  def render_markdown_to_html(text)
    sanitize(markdown_processor.render(text), tags: ApplicationHelper::MARKDOWN_TAGS)
  end

  def render_markdown_to_plain_text(text)
    markdown_text_processor.render(text)
  end

  def markdown_processor
    @markdown_processor ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  end

  def markdown_text_processor
    @markdown_text_processor ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown, autolink: true, tables: true)
  end
end
