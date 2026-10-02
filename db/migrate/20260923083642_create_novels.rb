class CreateNovels < ActiveRecord::Migration[7.2]
  def change
    create_table :novels do |t|
    t.references :user, null: false, foreign_key: true
    t.string :subtitle
    t.text :story

    t.integer :status, default: 0, null: false
    t.timestamps
    end
  end
end
