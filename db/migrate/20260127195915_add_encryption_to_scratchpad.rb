class AddEncryptionToScratchpad < ActiveRecord::Migration[8.1]
  def change
    add_column :scratchpads, :encrypted, :boolean, default: false, null: false
    add_column :scratchpads, :encryption_meta, :jsonb, default: {}, null: false
  end
end
