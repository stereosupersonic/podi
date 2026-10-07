# https://github.com/prashaantt/savitri/blob/master/app/views/audios/index.rss.builder

class PodcastFeedPresenter
  # UUIDv5 of "www.wartenberger.de/episodes.rss" in the Podcast Index namespace, computed once. It must
  # never change, even if the feed moves to another URL.
  GUID = "2bac87e9-7f7b-581e-aea8-44d36776e94a"

  attr_reader :episodes

  delegate_missing_to :current_setting

  def initialize(episondes)
    @episodes = EpisodeFeedPresenter.wrap episondes
  end

  def copyright
    "Copyright #{Time.current.year} #{owner}"
  end

  private

  def current_setting
    @current_setting ||= Setting.current
  end
end
