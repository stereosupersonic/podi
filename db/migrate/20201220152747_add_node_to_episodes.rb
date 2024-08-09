class AddNodeToEpisodes < ActiveRecord::Migration[6.1]
  def change
    add_column :episodes, :nodes, :text
    add_column :episodes, :active, :boolean, default: true
    add_column :episodes, :number, :integer, default: 0, null: false, index: { unique: true }
    add_column :episodes, :artwork_url, :string
  end
end
