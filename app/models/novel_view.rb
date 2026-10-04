class NovelView < ApplicationRecord
   belongs_to :user, optional: true # ゲスト対応のため optional
  belongs_to :novel, counter_cache: :view_counts_count # カウントを自動同期
end
