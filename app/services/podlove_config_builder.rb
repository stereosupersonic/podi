class PodloveConfigBuilder
  attr_reader :episode, :options

  def initialize(episode, options = {})
    @episode = episode
    @options = options
  end

  def config_json
    {
      :version => 5,
      :base => "/podlove-web-player/",
      :activeTab => "chapters", # default active tab, can be set to [chapters, files, share, playlist]
      :theme => {
        # /**
        #  * Tokens
        #  * - if defined the player defaults are dropped
        #  * - rgba as well as hex values are allowed
        #  * - use this generator to get a direct visual feedback:
        #  */
        tokens: {
          brand: "#166255",
          brandDark: "#166255",
          brandDarkest: "#1A3A4A",
          brandLightest: "#E5EAECFF",
          shadeDark: "#807E7C",
          shadeBase: "#807E7C",
          contrast: "#000",
          alt: "#fff"
        },

        # # /**
        # #  * Fonts
        # #  * - by default the system font stack is used (https://css-tricks.com/snippets/css/system-font-stack/)
        # #  *
        # #  * font:
        # #  * - name: font name that is used in the font stack
        # #  * - family: list of fonts in a fallback order
        # #  * - weight: font weight of the defined font
        # #  * - src: list of web font sources (allowed: woff, woff2, ttf, eot, svg)
        # #  */
        # fonts: {
        #   ci: {
        #     name: "RobotoBlack",
        #     family: [
        #       "RobotoBlack",
        #       "Calibri",
        #       "Candara",
        #       "Arial",
        #       "Helvetica",
        #       "sans-serif"
        #     ],
        #     weight: 900
        #     # src: ["./assets/Roboto-Black.ttf"]
        #   },
        #   regular: {
        #     name: "FiraSansLight",
        #     family: [
        #       "FiraSansLight",
        #       "Calibri",
        #       "Candara",
        #       "Arial",
        #       "Helvetica",
        #       "sans-serif"
        #     ],
        #     weight: 300,
        #     src: ["./assets/FiraSans-Light.ttf"]
        #   },
        #   bold: {
        #     name: "FiraSansBold",
        #     family: [
        #       "FiraSansBold",
        #       "Calibri",
        #       "Candara",
        #       "Arial",
        #       "Helvetica",
        #       "sans-serif"
        #     ],
        #     weight: 700
        #     # src: ["./assets/FiraSans-Bold.ttf"]
        #   }
        # }
      },

      # /**
      #  * Subscribe Button
      #  * - configuration for the subsscribe button overlay
      #  * - if not defined the subscribe button won't be rendered
      #  */
      # "subscribe-button" => {
      #   feed: "https://feeds.podlovers.org/mp3", # Rss feed

        # /**
        #  * Clients
        #  * - list of supported podcast clients on android, iOS, Windows, OSX
        #  * - only available clients on the used os/platform are shown
        #  * - order in list determines rendered order
        #  */
        # clients: [
        #   {
        #     id: "apple-podcasts"
        #     ##
        #   },
        #   {
        #     id: "antenna-pod"
        #   },
        #   {
        #     id: "beyond-pod"
        #   },
        #   {
        #     id: "castbox"
        #     # service: "castbox-id"
        #   },
        #   {
        #     id: "castro"
        #   },
        #   {
        #     id: "clementine"
        #   },
        #   {
        #     id: "downcast"
        #   },
        #   {
        #     id: "google-podcasts"
        #     # service: "https://feeds.podlovers.org/mp3" # // feed
        #   },
        #   {
        #     id: "gpodder"
        #   },
        #   {
        #     id: "itunes"
        #   },
        #   {
        #     id: "i-catcher"
        #   },
        #   {
        #     id: "instacast"
        #   },
        #   {
        #     id: "overcast"
        #   },
        #   {
        #     id: "player-fm"
        #   },
        #   {
        #     id: "pocket-casts"
        #   },
        #   {
        #     id: "pocket-casts"
        #     # service: "https://feeds.podlovers.org/mp3" # // feed
        #   },
        #   {
        #     id: "pod-grasp"
        #   },
        #   {
        #     id: "podcast-addict"
        #   },
        #   {
        #     id: "podcast-republic"
        #   },
        #   {
        #     id: "podcat"
        #   },
        #   {
        #     id: "podscout"
        #   },
        #   {
        #     id: "rss-radio"
        #   },
        #   {
        #     id: "rss"
        #   }
        # ]

      # /**
      #  * Playlist:
      #  * - can be a plain list or a reference to a json file
      #  * - if present playlist tab will be available
      #  */
      #:playlist => [],

      # /*
      #   Share Tab
      # */
      :share => {
        # /**
        #  * Share Channels:
        #  * - list of available channels in share tab
        #  */
        channels: [
          "twitter",
          "mail",
          "link"
        ],
        sharePlaytime: true,
        # /**
        #  * Share Outlet
        #  * - outlet path required in order to provide embed snippet
        #  * - also ensure that the configuration as well as the episode is available via urls to enable embedding
        # **/
        outlet: "/share.html"
      }
    }.to_json
  end

  # https://github.com/podigee/podigee-podcast-player/blob/master/docs/configuration.md
  def episodes_json
    {
      # // Configuration Version
      version: 5,

      # /**
      # * Show Related Information
      # */
      show: {
        title: "Podlovers",
        subtitle: "Der Podlove Entwickler:innen Podcast",
        summary: "Podlove ist eine Initiative zur Verbesserung der Open Source Infrastruktur zum Podcasting. Podlove ist gleichzeitig auch ein Netzwerk an Entwickler:innen zur Diskussion von Features und Standardisierung.",
        poster: "/assets/web-player/show.png",
        link: "https://podlovers.org"
      },

      # /**
      # * Episode related Information
      # */
      title: "Podlove Web Player",
      subtitle: "Podlove Web Player: Motivation, Geschichte, Features, Ausblick",
      summary: "Wir holen uns Simon zur Hilfe um \u00fcber die Anf\u00e4nge des Podlove Web Player zu sprechen: Warum es ihn gibt und wie die ersten Versionen aussahen. In der zweiten H\u00e4lfte geht es tief in den Technik-Kaninchenbau: Alex erl\u00e4utert seine Motivation f\u00fcr den Neubau f\u00fcr Podlove Web Player 4 und 5. Zum Schluss besprechen wir das holprige Release des aktuellen Web Player Plugins.",
      # // ISO 8601 DateTime format, this is capable of adding a time offset, see https://en.wikipedia.org/wiki/ISO_8601
      publicationDate: "2020-08-16T11:58:58+00:00",
      # // ISO 8601 Duration format ([hh]:[mm]:[ss].[sss]), capable of add ing milliseconds, see https://en.wikipedia.org/wiki/ISO_8601
      duration: "01:31:18.610",
      poster: "/assets/web-player/episode.png",
      link: "https://podlovers.org/podlove-web-player",

      # /**
      # * Chapters:
      # * - can be a plain list or a reference to a json file
      # * - if present chapters tab will be available
      # */
      chapters: [
        {
          start: "00:00:00.000",
          title: "Begr\u00fc\u00dfung",
          href: "",
          image: ""
        }
      ],

      # /**
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
          url: "https://files.podlovers.org/LOV003.mp3",
          size: "76976929",
          title: "MP3 Audio (mp3)",
          mimeType: "audio\/mpeg"
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
      files: [],

      # /**
      # * Contributors
      # * - used by info and transcripts tab
      # *
      # * Contributor
      # * - id: used as a reference in transcripts
      # * - name: name of the contributor
      # * - (avatar): avatar of the contributor
      # * - (group): contributors group
      # */
      contributors: [],

      # /**
      # * Transcripts:
      # * - can be a plain list or a reference to a json file
      # * - if present transcripts tab will be available (if the template includes it)
      # */
      transcripts: []
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
        result << {start: start, title: title}
      end
    end
  end
end
