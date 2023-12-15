class UpdateEpisodeCurrentStatisticsToVersion2 < ActiveRecord::Migration[7.1]
  def change
  
    update_view :episode_current_statistics, version: 2, revert_to_version: 1
  end
end
