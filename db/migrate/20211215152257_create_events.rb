class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.references :episode, null: false, foreign_key: true
      t.jsonb :data
      t.jsonb :metadata
      t.string :media_type

      t.timestamps
    end
  end
end
