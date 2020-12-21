class EpisodeUpdater < BaseService
  UPDATEABLE_ATTRIBUTES = %w[title description file_url file_size file_duration nodes active].freeze

  attr_accessor(*UPDATEABLE_ATTRIBUTES, :episode)

  delegate :id, to: :episode

  validates(*UPDATEABLE_ATTRIBUTES, presence: true)
  validates(:episode, presence: true)

  def call
    return false if invalid?

    episode.update! episode_attributes.merge(slug: build_slug)
  end

  private

  def build_slug
    "#{episode.number.to_s.rjust(3, '0')} #{title}".parameterize
  end

  def episode_attributes
    UPDATEABLE_ATTRIBUTES.map { |name| [name, send(name)] if send(name) }.compact.to_h
  end
end
