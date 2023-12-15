class CreateEpisodeStatistics < ActiveRecord::Migration[7.0]
  def change
    create_view :episode_statistics
  end
end
