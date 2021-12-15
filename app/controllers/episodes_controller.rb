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
    episode_record = Episode.find_by(slug: params[:slug])
    episode_record ||= Episode.find_by!(number: params[:slug][(/^\d+/)].to_i)
    @episode = EpisodePresenter.new episode_record
    if stale? episode_record, public: true
      respond_to do |format|
        # ETag caching https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-stale-3F
        format.html
        format.mp3 do
          ActiveSupport::Notifications.instrument(:track_mp3_downloads) do |payload|
            payload[:user_agent] = request.headers["User-Agent"]
            payload[:remote_ip] = request.remote_ip
            payload[:media_type] = request.media_type
            payload[:uuid] = request.uuid
            payload[:episode_id] = episode_record.id

            episode_record.increment! :downloads_count if track_downloads?
            redirect_to @episode # .file_url
          end
        end
      end
    end
  end

  private

  def track_downloads?
    params[:notracking].blank? && current_user.blank?
  end
end
