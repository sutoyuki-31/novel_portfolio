class CreateLibraries < ActiveRecord::Migration[7.2]
  def change
    create_table :libraries do |t|
      t.references :user
    t.string :title
    t.text :synopsis
    t.string :subtitle
    t.text :story
    t.integer :status, default: 0, null: false

    t.timestamps
    end
  end
end
