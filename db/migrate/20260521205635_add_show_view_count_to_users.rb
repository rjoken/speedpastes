class AddShowViewCountToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :show_view_count, :boolean, default: true, null: false
  end
end
