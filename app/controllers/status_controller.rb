require "episode_status_presenter"
class StatusController < ApplicationController
  before_action :authorize_admin

  def show

    @episode_records = Episode.order("number desc")
    @episodes = @episode_records.map do | episode |
      Rails.cache.fetch("#{episode.cache_key}_#{episode.updated_at.to_i}", expires_in: 5.minutes) do
        Rails.logger.info "NO CACHE!!!!!!!!!!"
        episode_presenter = EpisodeStatusPresenter.new(episode)
        episode_presenter.status
        episode_presenter
      end
    end
  end
end
