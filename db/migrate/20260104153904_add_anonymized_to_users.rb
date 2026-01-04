class AddAnonymizedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :anonymized_at, :datetime
    add_index :users, :anonymized_at
  end
end
