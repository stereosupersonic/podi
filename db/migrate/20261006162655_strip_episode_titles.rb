class StripEpisodeTitles < ActiveRecord::Migration[8.1]
  def up
    execute <<~'SQL'
      UPDATE episodes SET title = regexp_replace(title, '^\s+|\s+$', '', 'g')
      WHERE title ~ '^\s|\s$'
    SQL
  end

  # Surrounding whitespace carries no information, so there is nothing to restore.
  def down
  end
end
