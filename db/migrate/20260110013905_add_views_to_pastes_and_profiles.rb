class AddViewsToPastesAndProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :pastes, :views, :integer, default: 0, null: false
    add_column :users, :views, :integer, default: 0, null: false
  end
end
