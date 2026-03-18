class PodloveWebplayerConfigBuilder
  THEME_TOKENS = {
    brand: "#5c626e",
    brandDark: "#45494f",
    brandDarkest: "#25262a",
    brandLightest: "#edf0f5",
    shadeDark: "#25262a",
    shadeBase: "#5c626e",
    contrast: "#25262a",
    alt: "#f8f9fa"
  }.freeze

  SYSTEM_FONTS = [
    "system-ui", "-apple-system", "Segoe UI", "Roboto",
    "Helvetica Neue", "Arial", "sans-serif"
  ].freeze

  attr_reader :episode

  def initialize(episode)
    @episode = episode
  end

  def episode_config
    {
      poster: episode.artwork_url,
      duration: formatted_duration,
      audio: [
        {
          url: episode.mp3_url,
          mimeType: "audio/mpeg"
        }
      ],
      chapters: chapters
    }
  end

  def player_config
    {
      version: 5,
      activeTab: "chapters",
      theme: {
        tokens: THEME_TOKENS,
        fonts: {
          ci: { family: SYSTEM_FONTS },
          regular: { family: SYSTEM_FONTS },
          bold: { family: SYSTEM_FONTS, weight: 700 }
        }
      }
    }
  end

  private

  def formatted_duration
    return unless episode.duration.present?

    Time.at(episode.duration).utc.strftime("%H:%M:%S.000")
  end

  def chapters
    return [] if episode.chapter_marks.blank?

    episode.chapter_marks.each_line.filter_map do |line|
      next if line.blank?

      start, title = line.squish.split(/\s+/, 2)
      { start: start, title: title }
    end
  end
end
