class AddRssFeedToEpisodes < ActiveRecord::Migration[7.0]
  def change
    add_column :episodes, :rss_feed, :boolean, default: true
    add_index :episodes, :rss_feed
  end
end
