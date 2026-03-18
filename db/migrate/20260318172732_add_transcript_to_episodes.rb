class AddTranscriptToEpisodes < ActiveRecord::Migration[8.1]
  def change
    add_column :episodes, :transcript, :text
  end
end
