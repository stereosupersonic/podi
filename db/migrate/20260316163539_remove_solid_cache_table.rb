class RemoveSolidCacheTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :solid_cache_entries, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Solid Cache table cannot be recreated. Re-run the original migration if needed."
  end
end
