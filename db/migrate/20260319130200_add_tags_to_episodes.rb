class AddTagsToEpisodes < ActiveRecord::Migration[8.1]
  def change
    add_column :episodes, :tags, :text, array: true, default: []
    add_index :episodes, :tags, using: :gin
  end
end
