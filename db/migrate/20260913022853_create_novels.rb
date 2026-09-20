class CreateNovels < ActiveRecord::Migration[7.2]
  def change
    create_table :novels do |t|
    t.references :user



    t.integer :novel_number

      t.timestamps
    end
  end
end
