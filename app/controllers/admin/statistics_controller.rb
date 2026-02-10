module Admin
  class StatisticsController < Admin::BaseController
    ALLOWED_SORT_COLUMNS = %w[published_on a12h a1d a3d a7d a30d a60d a12m a24m cnt].freeze

    def index
      @episode_current_statistics = StatisticPresenter.wrap EpisodeCurrentStatistic.all.order("#{sort_column(:sort_current)} DESC")
      @episode_statistics = StatisticPresenter.wrap EpisodeStatistic.all.order("#{sort_column(:sort)} DESC")
    end

    private

    def sort_column(param_key)
      column = params.fetch(param_key, "a1d").to_s
      ALLOWED_SORT_COLUMNS.include?(column) ? column : "a1d"
    end
  end
end
