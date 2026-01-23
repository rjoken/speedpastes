class CreateUserSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest
      t.string :ip
      t.text :user_agent
      t.datetime :last_seen_at
      t.datetime :revoked_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :user_sessions, :token_digest, unique: true
    add_index :user_sessions, [ :user_id, :revoked_at ]
    add_index :user_sessions, :expires_at
  end
end
