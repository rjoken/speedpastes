class AddCollaboratorsToPaste < ActiveRecord::Migration[8.1]
  def change
    add_column :pastes, :collaborators, :bigint, array: true, default: [], null: false
    add_index :pastes, :collaborators, using: :gin
  end
end
