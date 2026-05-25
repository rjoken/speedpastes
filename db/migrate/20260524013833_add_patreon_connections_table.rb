class AddPatreonConnectionsTable < ActiveRecord::Migration[8.1]
  def change
    create_table :patreon_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :patreon_user_id, null: false
      t.string :patreon_username
      t.string :campaign_id
      t.string :patron_status
      t.datetime :last_synced_at
      t.timestamps
    end

    add_index :patreon_connections, :patreon_user_id, unique: true
  end
end
