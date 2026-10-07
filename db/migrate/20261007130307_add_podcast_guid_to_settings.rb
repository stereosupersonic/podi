class AddPodcastGuidToSettings < ActiveRecord::Migration[8.1]
  # The podcast's permanent ID in the feed: UUIDv5 of "www.wartenberger.de/episodes.rss" in the Podcast
  # Index namespace. Podcast apps already know it, so it is stored rather than computed again.
  WARTENBERGER_PODCAST_GUID = "2bac87e9-7f7b-581e-aea8-44d36776e94a".freeze

  def up
    add_column :settings, :podcast_guid, :string
    execute "UPDATE settings SET podcast_guid = '#{WARTENBERGER_PODCAST_GUID}'"
    change_column_null :settings, :podcast_guid, false
  end

  def down
    remove_column :settings, :podcast_guid
  end
end
