class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :username, null: false
      t.string :password_digest, null: false
      t.text :bio
      t.string :link
      t.references :invited_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
    add_index :users, "lower(username)", unique: true, name: "index_users_on_lower_username"
  end
end
