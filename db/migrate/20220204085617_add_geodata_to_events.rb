class AddGeodataToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :geo_data, :jsonb
  end
end
