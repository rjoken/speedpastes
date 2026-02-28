class CreateUserPins < ActiveRecord::Migration[8.1]
  def change
    create_table :user_pins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :paste, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    add_index :user_pins, [ :user_id, :paste_id ], unique: true
    add_index :user_pins, [ :user_id, :position ], unique: true
  end
end
