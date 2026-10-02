class AddLibraryToNovels < ActiveRecord::Migration[7.2]
  def change
    add_reference :novels, :library, null: false, foreign_key: true, index: false
    add_column :novels, :page_number, :integer
    add_index :novels, [ :library_id, :page_number ], unique: true
  end
end
