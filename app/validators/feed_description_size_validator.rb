# Podcast apps get the episode description from the RSS feed, built from the description, chapters,
# show notes and the contact block. Only the rendered result can be measured against Apple's limit.
class FeedDescriptionSizeValidator < ActiveModel::Validator
  def validate(episode)
    return if episode.description.blank?

    size = EpisodeFeedPresenter.new(episode).description_with_show_notes_html.bytesize
    limit = EpisodeFeedPresenter::MAX_DESCRIPTION_BYTES
    return if size <= limit

    episode.errors.add(:description, "makes the RSS feed description #{size} bytes, #{size - limit} more " \
                                     "than Apple allows (#{limit}). Shorten the description or show notes")
  end
end
