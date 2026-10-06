class UpdateEpisodeCurrentStatisticsToVersion3 < ActiveRecord::Migration[8.1]
  def change
    update_view :episode_current_statistics, version: 3, revert_to_version: 2
  end
end
