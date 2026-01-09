class CreateScratchpads < ActiveRecord::Migration[8.1]
  def change
    create_table :scratchpads do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :body, null: false, default: ""

      t.timestamps
    end
  end
end
