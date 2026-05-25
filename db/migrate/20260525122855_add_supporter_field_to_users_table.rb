class AddSupporterFieldToUsersTable < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :is_supporter, :boolean, default: false, null: false
  end
end
