class AddRenderTypeToPastes < ActiveRecord::Migration[8.1]
  def change
    add_column :pastes, :render_type, :integer, null: false, default: 0
    add_index :pastes, :render_type
  end
end
