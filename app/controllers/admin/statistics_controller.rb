class Admin::StatisticsController <  Admin::BaseController
  def index
    sort_column = params.fetch(:sort, :cnt)
    @episode_statistics = EpisodeStatistic.all.order("#{sort_column} DESC")
  end
end
