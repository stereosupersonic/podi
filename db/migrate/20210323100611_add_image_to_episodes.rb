class AddImageToEpisodes < ActiveRecord::Migration[6.1]
  def change
    add_column :episodes, :image_data, :text
  end
end
