class CreateNovelViews < ActiveRecord::Migration[7.2]
  def change
    create_table :novel_views do |t|
      t.references :user, foreign_key: true
      t.references :novel, null: false, foreign_key: true
      t.string :session_id

      t.timestamps
    end
    add_index :novel_views, :session_id
  end
end
