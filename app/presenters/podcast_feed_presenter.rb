# https://github.com/prashaantt/savitri/blob/master/app/views/audios/index.rss.builder

class PodcastFeedPresenter
  attr_reader :episodes

  delegate_missing_to :current_setting

  def initialize(episodes)
    @episodes = EpisodeFeedPresenter.wrap episodes
  end

  def copyright
    "Copyright #{Time.current.year} #{owner}"
  end

  private

  def current_setting
    @current_setting ||= Setting.current
  end
end
