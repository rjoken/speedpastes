class AddTagsToPastes < ActiveRecord::Migration[8.1]
  def change
    add_column :pastes, :tags, :string, array: true, default: []
  end
end
