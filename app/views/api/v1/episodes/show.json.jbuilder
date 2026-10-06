json.episode do
  json.extract! @episode, :id, :number, :slug, :title, :published_on, :active, :visible, :tags, :duration
  json.preview_url EpisodePresenter.new(@episode).episode_url
end
