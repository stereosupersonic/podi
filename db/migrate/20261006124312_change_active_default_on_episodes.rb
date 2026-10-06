class ChangeActiveDefaultOnEpisodes < ActiveRecord::Migration[8.1]
  def change
    change_column_default :episodes, :active, from: true, to: false
  end
end
