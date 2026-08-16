class AddFrontpageBoolToPastes < ActiveRecord::Migration[8.1]
  def change
    add_column :pastes, :hide_frontpage, :boolean, null: false, default: false
  end
end
