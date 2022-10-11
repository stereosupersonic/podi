require "rails_helper"

RSpec.describe EpisodeFeedPresenter, type: :model do
  let!(:setting) { FactoryBot.create(:setting) }

  let!(:nodes) do
    <<~MARKDOWN
      * [link](https://test.com)
      * [link2](https://test.com)
    MARKDOWN
  end

  let!(:chapter_marks) do
    <<~MARKDOWN
      00:00:00.001 	Intro
      00:01:00.001 	Begrüßung
      00:04:34.001 	Outro
    MARKDOWN
  end

  let(:episode) { FactoryBot.create :episode, nodes: nodes, chapter_marks: chapter_marks }
  let(:presenter) { EpisodeFeedPresenter.new(episode) }
  it "generate a valid markdown  chapter_list" do
    expect(presenter.chapter_list).to eq(
      <<~MARKDOWN.strip
        Kapitelmarken:
        • 00:00:00 - Intro
        • 00:01:00 - Begrüßung
        • 00:04:34 - Outro
      MARKDOWN
    )
  end

  it "generate a valid html description" do
    expected_html = <<~HTML.strip
    <p>we talk about bikes and things</p>
    <br /><p>Kapitelmarken:<br />
    • 00:00:00 - Intro<br />
    • 00:01:00 - Begrüßung<br />
    • 00:04:34 - Outro</p>
    <br /><h3>Show Notes</h3>
    <ul>
    <li><a href="https://test.com">link</a></li>
    <li><a href="https://test.com">link2</a></li>
    </ul>
    <br />
    <h2>Kontakt</h2>
    <p>
      <br />
      <b>Schreibt uns!</b>
      <br />
      Schickt uns eure Themenwünsche und euer Feedback.<br />
      <a href='mailto:admin@wartenberger.de'>admin@wartenberger.de</a>
      <br />
      <br />
      <b>Folgt uns!</b>
      <br />
      Bleibt auf dem Laufenden über zukünftige Folgen
      <br />
      <a href='https://twitter.com/WartenbergerPod'>Twitter</a>
      <br />
      <a href='https://www.instagram.com/wartenbergerpodcast'>Instagram</a>
      <br />
      <a href='https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563'>Facebook</a>
      <br />
      <a href='https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg'>YouTube</a>
      <br />
    </p>
    HTML
    expect(presenter.description_with_show_notes_html.squish).to match_html(expected_html)
  end

  it "generate a valid text description" do
    expected_text = <<~TEXT.strip
      we talk about bikes and things

      Kapitelmarken:
      • 00:00:00 - Intro
      • 00:01:00 - Begrüßung
      • 00:04:34 - Outro

      Show Notes
      link (https://test.com)
      link2 (https://test.com)

      Kontakt
      Schreibt uns!
      Schickt uns eure Themenwünsche und euer Feedback.
      admin@wartenberger.de (mailto:admin@wartenberger.de)
      Folgt uns!
      Bleibt auf dem Laufenden über zukünftige Folgen
      Twitter (https://twitter.com/WartenbergerPod)
      Instagram (https://www.instagram.com/wartenbergerpodcast)
      Facebook (https://www.facebook.com/Wartenberger-Der-Podcast-102909105061563)
      YouTube (https://www.youtube.com/channel/UCfnC8JiraR8N8QUkqzDsQFg)
    TEXT

    expect(presenter.description_with_show_notes_text.strip).to eq(expected_text.strip)
  end
end
