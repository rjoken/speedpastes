class AddOptOutOfSupporterTagToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :show_supporter, :boolean, default: true, null: false
  end
end
