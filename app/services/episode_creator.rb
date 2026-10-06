class EpisodeCreator < BaseService
  attr_accessor :episode_attributes

  # Returns the episode; callers check persisted? and render its errors otherwise.
  def call
    episode = Episode.new(episode_attributes)
    episode.number = Episode.next_number unless episode.number.to_i.positive?
    episode.slug = episode.build_slug
    episode.save
    episode
  end
end
