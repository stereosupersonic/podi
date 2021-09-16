class CreateImages < ActiveRecord::Migration[6.1]
  def change
    create_table :images do |t|
      t.belongs_to :episode, null: false, foreign_key: true
      t.integer :element_order, default: 0, null: false
      t.string :cloudinary_public_id, null: false
      t.string :title
      t.text :description
      t.timestamps
    end
  end
end
