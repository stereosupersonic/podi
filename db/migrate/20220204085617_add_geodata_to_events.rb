class AddGeodataToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :geo_data, :jsonb, default: {}
  end
end
