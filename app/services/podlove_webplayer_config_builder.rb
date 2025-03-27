class PodloveWebplayerConfigBuilder
  attr_reader :setting

  def initialize(setting:)
    @setting = setting
  end

  # Based on https://docs.podlove.org/podlove-web-player/
  def to_json(*_args)
    {
      # Configuration Version
      :version => 5,
      # player asset base path, falls back to ./
      :base => "player/",
      # default active tab, can be set to [chapters, files, share, playlist]
      :activeTab => "chapters",

      # * Tokens
      # * - if defined the player defaults are dropped
      # * - rgba as well as hex values are allowed
      :theme => {
        tokens: {
          brand: "#E64415",
          brandDark: "#235973",
          brandDarkest: "#1A3A4A",
          brandLightest: "#E5EAECFF",
          shadeDark: "#807E7C",
          shadeBase: "#807E7C",
          contrast: "#000",
          alt: "#000"
        },

        # /**
        # * Fonts
        # * - by default the system font stack is used (https://css-tricks.com/snippets/css/system-font-stack/)
        # *
        # * font:
        # * - name: font name that is used in the font stack
        # * - family: list of fonts in a fallback order
        # * - weight: font weight of the defined font
        # * - src: list of web font sources (allowed: woff, woff2, ttf, eot, svg)
        # */

        fonts: {
          ci: {
            name: "RobotoBlack",
            family: [
              "RobotoBlack",
              "Calibri",
              "Candara",
              "Arial",
              "Helvetica",
              "sans-serif"
            ],
            weight: 900

          },
          regular: {
            name: "FiraSansLight",
            family: [
                "FiraSansLight",
                "Calibri",
                "Candara",
                "Arial",
                "Helvetica",
                "sans-serif"
              ],
            weight: 300

          },
          bold: {
            name: "FiraSansBold",
            family: [
                "FiraSansBold",
                "Calibri",
                "Candara",
                "Arial",
                "Helvetica",
                "sans-serif"
              ],
            weight: 700

          }
        }
      },

      # /**
      # * Fonts
      # * - by default the system font stack is used (https://css-tricks.com/snippets/css/system-font-stack/)
      # *
      # * font:
      # * - name: font name that is used in the font stack
      # * - family: list of fonts in a fallback order
      # * - weight: font weight of the defined font
      # * - src: list of web font sources (allowed: woff, woff2, ttf, eot, svg)
      # */
      "subscribe-button" => {
        feed: "https://feeds.podlovers.org/mp3",

        # /**
        # * Fonts
        # * - by default the system font stack is used (https://css-tricks.com/snippets/css/system-font-stack/)
        # *
        # * font:
        # * - name: font name that is used in the font stack
        # * - family: list of fonts in a fallback order
        # * - weight: font weight of the defined font
        # * - src: list of web font sources (allowed: woff, woff2, ttf, eot, svg)
        # */
        clients: [
            { id: "apple-podcasts", service: "id1523714548" },

            { id: "castbox", service: "castbox-id" },

            { id: "downcast" },
            { id: "google-podcasts", service: "https://feeds.podlovers.org/mp3" },

            { id: "instacast" },
            { id: "overcast" },
            { id: "pocket-casts" },
            { id: "pocket-casts", service: "https://feeds.podlovers.org/mp3" },
            { id: "rss-radio" },
            { id: "rss" }
          ]
      },

      # /**
      # * Playlist:
      # * - can be a plain list or a reference to a json file
      # * - if present playlist tab will be available
      # */

      :playlist => [
          {
            title: "Podlove Web Player",
            config: "https://backend.podlovers.org/wp-json/podlove-web-player/shortcode/publisher/60",
            duration: "01:31:18.610"
          },
          {
            title: "Podlove Publisher",
            config: "https://backend.podlovers.org/wp-json/podlove-web-player/shortcode/publisher/51",
            duration: "02:03:30.573"
          },
          {
            title: "Wir. Müssen Reden",
            config: "https://backend.podlovers.org/wp-json/podlove-web-player/shortcode/publisher/15",
            duration: "00:50:03.900"
          }
        ],
      :share => {
        # /**
        # * Share Channels:
        # * - list of available channels in share tab
        # */
        channels: [
          "twitter",
          "mail",
          "link"
        ],
        sharePlaytime: true
        #   /**
        #   * Share Outlet
        #   * - outlet path required in order to provide embed snippet
        #   * - also ensure that the configuration as well as the episode is available via urls to enable embedding
        #  **/
        #  outlet: "/share.html",
      }

    }.to_json
  end
end
