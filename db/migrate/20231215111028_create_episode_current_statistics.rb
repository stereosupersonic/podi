class CreateEpisodeCurrentStatistics < ActiveRecord::Migration[7.1]
  def change
    create_view :episode_current_statistics
  end
end
