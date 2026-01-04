class CreatePastes < ActiveRecord::Migration[8.1]
  def change
    create_table :pastes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :shortcode, null: false
      t.string :title
      t.text :body, null: false
      t.integer :visibility, null: false, default: 0

      t.timestamps
    end

    add_index :pastes, :shortcode, unique: true
    add_index :pastes, [ :user_id, :created_at ]
    add_index :pastes, [ :visibility, :created_at ]
  end
end
