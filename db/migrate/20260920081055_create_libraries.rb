class CreateLibraries < ActiveRecord::Migration[7.2]
  def change
    create_table :libraries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :synopsis
      t.string :genre
      t.string :tag
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
