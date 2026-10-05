# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_10_05_120000) do
  create_table "libraries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.text "synopsis"
    t.integer "genre", null: false
    t.string "tag"
    t.integer "status", default: 0, null: false
    t.integer "genre_filter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_likes_count", default: 0, null: false
    t.integer "total_views_count", default: 0, null: false
    t.index ["user_id"], name: "index_libraries_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "novel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["novel_id"], name: "index_likes_on_novel_id"
    t.index ["user_id", "novel_id"], name: "index_likes_on_user_id_and_novel_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "novel_views", force: :cascade do |t|
    t.integer "user_id"
    t.integer "novel_id", null: false
    t.string "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["novel_id"], name: "index_novel_views_on_novel_id"
    t.index ["session_id"], name: "index_novel_views_on_session_id"
    t.index ["user_id"], name: "index_novel_views_on_user_id"
  end

  create_table "novels", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "subtitle"
    t.text "story"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "library_id", null: false
    t.integer "page_number"
    t.integer "view_counts_count", default: 0, null: false
    t.index ["library_id", "page_number"], name: "index_novels_on_library_id_and_page_number", unique: true
    t.index ["user_id"], name: "index_novels_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "libraries", "users"
  add_foreign_key "likes", "novels"
  add_foreign_key "likes", "users"
  add_foreign_key "novel_views", "novels"
  add_foreign_key "novel_views", "users"
  add_foreign_key "novels", "libraries"
  add_foreign_key "novels", "users"
end
