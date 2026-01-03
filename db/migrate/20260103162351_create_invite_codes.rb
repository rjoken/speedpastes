class CreateInviteCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :invite_codes do |t|
      t.string :code
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :used_by, foreign_key: { to_table: :users }
      t.datetime :used_at
      t.integer :max_uses, default: 1
      t.integer :uses_count, default: 0

      t.timestamps
    end
    add_index :invite_codes, :code, unique: true
  end
end
