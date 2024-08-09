class PodigeeWebplayerConfigBuilder
  attr_reader :episode, :options

  def initialize(episode, options = {})
    @episode = episode
    @options = options
  end

  # https://github.com/podigee/podigee-podcast-player/blob/master/docs/configuration.md
  def to_json(*_args)
    {
      options: {
        # https://github.com/podigee/podigee-podcast-player/blob/master/docs/theming.md
        theme: options.fetch(:theme, "default"),
        startPanel: "ChapterMarks"
      },
      extensions: {
        ChapterMarks: {},
        # EpisodeInfo: {},
        # Playlist: {},
        # Transcript: {},
        SubscribeBar: {}
      },
      episode: { media: {
                   mp3: episode.mp3_url
                 },
                 coverUrl: nil, # episode.artwork_url,
                 title: (@options[:title] ? episode.title : nil),
                 subtitle: nil,
                 url: episode.episonde_url,
                 description: (@options[:info] ? episode.description : nil),
                 chaptermarks: chapter_marks }
    }.to_json
  end

  private

  def chapter_marks
    return nil if episode.chapter_marks.blank?

    # example
    # https://github.com/podigee/podigee-podcast-player/blob/8300f3418c757ab1746878e2d2a428c3e8752002/example/config.json#L36-L57
    #
    # [
    #   {"start": "00:00:00.000", "title": "Intro"},
    #   {"start": "00:00:41.018", "title": "Begrüßung"},
    #   {"start": "00:01:30.542", "title": "Vorstellung"},
    #   {"start": "00:05:48.377", "title": "Aufgaben des Wirtschaftsjournalismus"},
    #   {"start": "00:10:29.462", "title": "Neuer Studiengang"}
    # ]

    [].tap do |result|
      episode.chapter_marks.each_line do |line|
        next if line.blank?

        start, title = *line.squish.split(/\s+/, 2)
        result << { start: start, title: title }
      end
    end
  end
end
