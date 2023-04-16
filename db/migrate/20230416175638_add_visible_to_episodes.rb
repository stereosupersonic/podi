class AddVisibleToEpisodes < ActiveRecord::Migration[7.0]
  def change
    add_column :episodes, :visible, :boolean, default: true
  end
end
