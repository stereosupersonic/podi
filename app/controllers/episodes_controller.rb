class EpisodesController < ApplicationController
  def index
    published = Episode.published
    @episodes_records = published.paginate(page: params[:page], per_page: params[:per_page])
    @episodes = EpisodePresenter.wrap @episodes_records

    respond_to do |format|
      format.html
      format.rss do
        @episodes_records = published.where(rss_feed: true)
        @feed = PodcastFeedPresenter.new(@episodes_records)
        render layout: false, content_type: "application/xml"
      end
    end
  end

  def show
    episode_record = Episode.visible.find_by(slug: params[:slug])
    episode_record ||= Episode.visible.find_by!(number: params[:slug][(/^\d+/)].to_i)

    @episode = EpisodePresenter.new episode_record
    if stale? episode_record, public: true
      respond_to do |format|
        # ETag caching https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-stale-3F
        format.html
        format.mp3 do
          Rails.logger.warn("NO REMOTE IP") if request.remote_ip.blank?
          key = Base64.encode64("episode_#{@episode.id}_#{request.remote_ip.presence || rand(1..100)}")

          if !Rails.cache.exist?(key) && track_downloads?
            Rails.cache.write(key, true, expires_in: 2.minutes)
            ActiveSupport::Notifications.instrument("track_mp3_downloads") do |payload|
              data = {}
              data[:user_agent] = request.headers["User-Agent"]
              data[:remote_ip] = request.remote_ip
              data[:uuid] = request.uuid
              payload[:downloaded_at] = Time.current
              payload[:data] = data
              payload[:episode_id] = episode_record.id
            end

          end

          redirect_to @episode.file_url, allow_other_host: true
        end
      end
    end
  end

  private

  def track_downloads?
    params[:notracking].blank? && current_user.blank?
  end
end
