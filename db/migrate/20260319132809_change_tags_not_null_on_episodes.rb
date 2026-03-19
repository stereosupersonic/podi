class ChangeTagsNotNullOnEpisodes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :episodes, :tags, false
  end
end
