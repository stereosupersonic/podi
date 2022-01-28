class EventPresenter < ApplicationPresenter
  def downloaded_at
    h.format_datetime o.downloaded_at
  end

  def info
  end

  def episode_title
    EpisodePresenter.new(episode).to_s
  end
end
