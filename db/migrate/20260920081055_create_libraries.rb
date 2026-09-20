class CreateLibraries < ActiveRecord::Migration[7.2]
  def change
    create_table :libraries do |t|
    t.string :title
    t.text :synopsis
    t.integer :novel_number

      t.timestamps
    end
  end
end
