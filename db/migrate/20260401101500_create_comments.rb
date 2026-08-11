class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.integer :episode_id
      t.integer :user_id
      t.string :body
      t.string :author_name
      t.string :author_email
      t.string :status, default: 'pending'
      t.integer :parent_id
      t.timestamps
    end

    add_column :episodes, :comments_count, :integer, default: 0

    Episode.reset_column_information
    Episode.find_each do |episode|
      episode.update_column(:comments_count, Comment.where("episode_id = #{episode.id}").count)
    end
  end
end
