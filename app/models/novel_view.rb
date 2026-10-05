class NovelView < ApplicationRecord
  belongs_to :user, optional: true # ゲスト対応のため optional
  belongs_to :novel, counter_cache: :view_counts_count # カウントを自動同期

  # counter_cache は Novel のコールバックを通らないため、
  # ライブラリの閲覧数はここで加算する
  # (毎回の再集計ではなく +1 の加算なので、アクセスが多くても軽い)
  after_create_commit :increment_library_total_views

  private

  def increment_library_total_views
    Library.update_counters(novel.library_id, total_views_count: 1)
  end
end
