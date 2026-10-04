class AddLibraryToNovels < ActiveRecord::Migration[7.2]
  def change
    add_reference :novels, :library, null: false, foreign_key: true, index: false
    add_column :novels, :page_number, :integer
    add_index :novels, [ :library_id, :page_number ], unique: true

    add_column :novels, :view_counts_count, :integer, default: 0, null: false

    add_column :libraries, :total_likes_count, :integer, default: 0, null: false
    add_column :libraries, :total_views_count, :integer, default: 0, null: false
  end
end
