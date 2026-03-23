class SetAdminDefaultOnUsers < ActiveRecord::Migration[8.1]
  def up
    User.where(admin: nil).update_all(admin: false)
    change_column_default :users, :admin, false
    change_column_null :users, :admin, false
  end

  def down
    change_column_null :users, :admin, true
    change_column_default :users, :admin, nil
  end
end
