class CreateAccountChangeRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :account_change_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :kind
      t.string :new_email
      t.string :new_username
      t.string :new_password_digest
      t.datetime :expires_at
      t.datetime :used_at

      t.timestamps
    end
  end
end
