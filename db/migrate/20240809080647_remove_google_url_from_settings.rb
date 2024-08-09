class RemoveGoogleUrlFromSettings < ActiveRecord::Migration[7.1]
  def change
   remove_column :settings, :google_url, :string
  end
end
