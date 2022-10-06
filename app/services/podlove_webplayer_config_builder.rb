class PodloveWebplayerConfigBuilder
  attr_reader :episode, :options

  def initialize(episode, options = {})
    @episode = episode
    @options = options
  end

  # https://github.com/podigee/podigee-podcast-player/blob/master/docs/configuration.md
  def to_json(*_args)
      {
        version: 5,
        base: "player/"

      }.to_json
  end

end
