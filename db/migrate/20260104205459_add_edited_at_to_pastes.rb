class AddEditedAtToPastes < ActiveRecord::Migration[8.1]
  def change
    add_column :pastes, :edited_at, :datetime
  end
end
