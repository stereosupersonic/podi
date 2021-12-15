class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.references :episode, null: false, foreign_key: true
      t.string :uuid
      t.string :user_agent
      t.string :remote_ip
      t.string :media_type

      t.timestamps
    end
  end
end