class MigrateFromDeviseToCustomAuth < ActiveRecord::Migration[8.0]
  def change
    # Rename encrypted_password to password_digest for has_secure_password
    rename_column :users, :encrypted_password, :password_digest

    # Remove Devise-specific columns that we no longer need
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime

    # Remove the index on reset_password_token
    remove_index :users, name: "index_users_on_reset_password_token" if index_exists?(:users, :reset_password_token, name: "index_users_on_reset_password_token")
  end
end
