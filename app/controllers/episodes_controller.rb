class EpisodesController < ApplicationController
  def index
    @episodes_records = Episode.published.paginate(page: params[:page], per_page: params[:per_page])
    @episodes = EpisodePresenter.wrap @episodes_records

    respond_to do |format|
      format.html
      format.rss do
        @feed = PodcastFeedPresenter.new(@episodes)
        render layout: false, content_type: "application/xml"
      end
    end
  end

  def show
    episode_record = Episode.find_by!(slug: params[:slug])
    @episode = EpisodePresenter.new episode_record
    if stale? episode_record, public: true
      respond_to do |format|
        # ETag caching https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-stale-3F
        format.html
        format.mp3 do
          episode_record.increment! :downloads_count unless params[:notracking]
          redirect_to @episode.file_url
        end
      end
    end
  end
end
