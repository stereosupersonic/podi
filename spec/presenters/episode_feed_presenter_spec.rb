require "rails_helper"

RSpec.describe EpisodeFeedPresenter, type: :model do
  it "generate a valid html chapter_list" do
    nodes = <<~MARKDOWN
      * [link](https://test.com)
      * [link2](https://test.com)
    MARKDOWN
    chapter_marks = <<~MARKDOWN
      00:00:00.001 	Intro
      00:01:00.001 	Begrüßung
      00:04:34.001 	Outro
    MARKDOWN
    episode = FactoryBot.create :episode, number: 2, title: "Anton Müller",
      nodes: nodes, chapter_marks: chapter_marks
    presenter = EpisodeFeedPresenter.new(episode)

    expect(presenter.chapter_list_html).to eq(
      "<p>\nKapitelmarken: <br>• 00:00:00 - Intro<br>• 00:01:00 - Begrüßung<br>• 00:04:34 - Outro\n</p>"
    )
  end
end
