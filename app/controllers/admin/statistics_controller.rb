module Admin
  class StatisticsController < Admin::BaseController
    def index
      @episode_current_statistics = StatisticPresenter.wrap EpisodeCurrentStatistic.all.order("#{params.fetch(
        :sort_current, :a1d
      )} DESC")
      @episode_statistics = StatisticPresenter.wrap EpisodeStatistic.all.order("#{params.fetch(:sort, :a1d)} DESC")
    end
  end
end
