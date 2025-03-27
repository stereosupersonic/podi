class PodloveWebplayerEpisodeBuilder
  attr_reader :episode, :setting, :options

  def initialize(episode:, setting:, options: {})
    @episode = episode
    @options = options
    @setting = setting
  end

  # Based on https://docs.podlove.org/podlove-web-player/

  # https://docs.podlove.org/podlove-web-player/v5/configuration
  def to_json(*_args)
    {
      # Configuration Version
      version: 5,
      # /**
      # * Show Related Information
      # */
      show: {
        title: "Podlovers",
        subtitle: "Der Podlove Entwickler:innen Podcast",
        summary: "Podlove ist eine Initiative zur Verbesserung der Open Source Infrastruktur zum Podcasting. Podlove ist gleichzeitig auch ein Netzwerk an Entwickler:innen zur Diskussion von Features und Standardisierung.",
        link: "https://podlovers.org"
      },
      # /**
      # * Episode related Information
      # */
      title: "Podlove Web Player",
      subtitle: "Podlove Web Player: Motivation, Geschichte, Features, Ausblick",
      summary: "Wir holen uns Simon zur Hilfe um über die Anfänge des Podlove Web Player zu sprechen: Warum es ihn gibt und wie die ersten Versionen aussahen. In der zweiten Hälfte geht es tief in den Technik-Kaninchenbau: Alex erläutert seine Motivation für den Neubau für Podlove Web Player 4 und 5. Zum Schluss besprechen wir das holprige Release des aktuellen Web Player Plugins.",
      publicationDate: "2020-08-16T11:58:58+00:00", # ISO 8601 DateTime format
      duration: "01:31:18.610", # ISO 8601 Duration format ([hh]:[mm]:[ss].[sss]), capable of add ing milliseconds, see https://en.wikipedia.org/wiki/ISO_8601
      link: "https://podlovers.org/podlove-web-player",
      # /**
      # * Chapters:
      # * - can be a plain list or a reference to a json file
      # * - if present chapters tab will be available
      # */
      chapters: [
      { start: "00:00:00.000", title: "Begrüßung", href: "", image: "" },
      { start: "00:00:26.196", title: "Simon", href: "", image: "" },
      { start: "00:01:56.397", title: "Feedback", href: "", image: "" },
      { start: "00:07:08.279", title: "Erfahrungen beim Publishen", href: "", image: "" },
      { start: "00:13:29.226", title: "Shownotes", href: "", image: "" },
      { start: "00:20:43.264", title: "Audio-Hardware", href: "", image: "" },
      { start: "00:22:51.183", title: "Podlove Web Player: Warum eigentlich?", href: "", image: "" },
      { start: "00:25:41.451", title: "Podlove Web Player 1", href: "", image: "" },
      { start: "00:28:16.131", title: "Podlove Web Player 2", href: "", image: "" },
      { start: "00:33:44.999", title: "Podlove Web Player 3", href: "", image: "" },
      { start: "00:44:17.011", title: "Podlove Web Player 4", href: "", image: "" },
      { start: "01:02:41.149", title: "Podlove UI", href: "", image: "" },
      { start: "01:05:50.035", title: "Podlove Web Player 5", href: "", image: "" },
      { start: "01:12:50.121", title: "Podlove Web Player WordPress Plugin", href: "", image: "" },
      { start: "01:29:23.552", title: "Ausblick", href: "", image: "" },
      { start: "01:30:49.849", title: "Und Tschüss", href: "", image: "" }
    ],
      #   /**
      #   * Audio Assets
      #   * - media Assets played by the audio player
      #   * - format support depends on the used browser (https://en.wikipedia.org/wiki/HTML5_audio#Supported_audio_coding_formats)
      #   * - also supports HLS streams
      #   *
      #   * Asset
      #   * - url: absolute path to media asset
      #   * - size: file size in  byte
      #   * - (title): title to be displayed in download tab
      #   * - mimeType: media asset mimeType
      # */
      audio: [
      {
        url: episode.mp3_url,
        size: "76976929",
        title: "MP3 Audio (mp3)",
        mimeType: "audio/mpeg"
      }
    ],
      # /**
      # * Files
      # * - list of files available for download
      # * - if no files are present, audio assets will be used as downloads
      # *
      # * Asset
      # * - url: absolute path to media asset
      # * - size: file size in  byte
      # * - title: title to be displayed in download tab
      # * - (mimeType): media asset mimeType
      # */
      files: [
      {
        url: episode.mp3_url,
        size: "76976929",
        title: "MP3 Audio",
        mimeType: "audio/mpeg"
      }
    ],
      contributors: [],

      #   /**
      # * Transcripts:
      # * - can be a plain list or a reference to a json file
      # * - if present transcripts tab will be available (if the template includes it)
      # */
      transcripts: [
      {
        start: "00:00:00.005",
        start_ms: 5,
        end: "00:00:09.458",
        end_ms: 9458,
        speaker: "3",
        voice: "Eric",
        text: "Dann sage ich einfach mal: Hallo und willkommen zu Episode drei des Podlovers Podcasts. Heute das erste Mal mit Gast. Hallo Simon."
      },
      {
        start: "00:00:09.600",
        start_ms: 9600,
        end: "00:00:10.800",
        end_ms: 10800,
        speaker: "4",
        voice: "Simon",
        text: "Hallo."
      },
      {
        start: "00:00:10.996",
        start_ms: 10996,
        end: "00:00:13.875",
        end_ms: 13875,
        speaker: "3",
        voice: "Eric",
        text: "Außerdem wieder mit Michi."
      },
      {
        start: "00:00:14.900",
        start_ms: 14900,
        end: "00:00:15.900",
        end_ms: 15900,
        speaker: "2",
        voice: "Michi",
        text: "Hallo."
      },
      {
        start: "00:00:16.000",
        start_ms: 16000,
        end: "00:00:16.300",
        end_ms: 16300,
        speaker: "3",
        voice: "Eric",
        text: "Und Alex."
      }
    ]

    }.to_json
  end

  private

  def chapter_marks
    return [] if episode.chapter_marks.blank?

    # Podlove Web Player requires chapters in the format:
    # [
    #   { start: "00:00:00.000", title: "Intro", href: "", image: "" },
    #   { start: "00:00:41.018", title: "Begrüßung", href: "", image: "" }
    # ]

    [].tap do |result|
      episode.chapter_marks.each_line do |line|
        next if line.blank?

        start, title = *line.squish.split(/\s+/, 2)
        result << { start: start, title: title, href: "", image: "" }
      end
    end
  end
end
