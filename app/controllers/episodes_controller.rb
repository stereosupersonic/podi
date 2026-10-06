class EpisodesController < ApplicationController
  PER_PAGE = 5

  def index
    published = Episode.published
    @episodes_records = published.paginate(page: params[:page], per_page: PER_PAGE)
    @episodes = EpisodePresenter.wrap @episodes_records

    respond_to do |format|
      format.html do
        if request.xhr?
          render partial: "episodes/page",
                 locals: { episodes: @episodes,
                           next_page: @episodes_records.next_page }
        end
      end
      format.rss do
        @episodes_records = published.where(rss_feed: true)
        @feed = PodcastFeedPresenter.new(@episodes_records)
        render layout: false, content_type: "application/xml"
      end
    end
  end

  def search
    @query = params[:q].to_s.strip
    episodes = Episode.published.search(@query).limit(20)
    @episodes = EpisodePresenter.wrap(episodes)
  end

  def show
    episode_record = Episode.visible.find_by(slug: params[:slug])
    episode_record ||= Episode.visible.find_by!(number: params[:slug][/^\d+/].to_i)

    @episode = EpisodePresenter.new episode_record

    respond_to do |format|
      # ETag caching https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-stale-3F
      format.html { fresh_when episode_record, public: true }
      # Not conditional: every mp3 request has to reach the download tracking.
      format.mp3 do
        Rails.logger.warn("NO REMOTE IP") if request.remote_ip.blank?
        key = "episode_#{@episode.id}_#{request.remote_ip.presence || rand(1..100)}"

        if !Rails.cache.exist?(key) && track_downloads?
          Rails.cache.write(key, true, expires_in: 2.minutes)
          ActiveSupport::Notifications.instrument("track_mp3_downloads") do |payload|
            payload[:downloaded_at] = Time.current
            payload[:data] = {
              user_agent: request.headers["User-Agent"],
              remote_ip: request.remote_ip,
              uuid: request.uuid
            }
            payload[:episode_id] = episode_record.id
          end
        end

        redirect_to @episode.cdn_url, allow_other_host: true
      end
    end
  end

  private

  def track_downloads?
    params[:notracking].blank? && current_user.blank?
  end
end
