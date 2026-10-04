class Like < ApplicationRecord
  belongs_to :user
  belongs_to :novel

  after_create_commit  { novel.library.update_total_counts }
  after_destroy_commit { novel.library.update_total_counts }
   validates :user_id, uniqueness: { scope: :novel_id }
end
