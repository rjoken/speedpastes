class CreateUserpages < ActiveRecord::Migration[8.1]
  def change
    create_table :userpages do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :paste, null: true, foreign_key: true
      t.timestamps
    end
  end
end
