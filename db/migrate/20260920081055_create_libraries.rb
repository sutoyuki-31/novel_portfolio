class CreateLibraries < ActiveRecord::Migration[7.2]
  def change
    create_table :libraries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :synopsis
      t.integer :genre, null: false
      t.string :tag
      t.integer :status, default: 0, null: false
      t.integer :genre_filter
      t.timestamps
    end
  end
end
