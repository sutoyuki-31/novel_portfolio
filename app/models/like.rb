class Like < ApplicationRecord
  belongs_to :user
  belongs_to :novel

  # アプリ側のチェック。DB側は [user_id, novel_id] のユニークインデックスで保証する
  validates :user_id, uniqueness: { scope: :novel_id }

  after_create_commit :refresh_library_total_counts
  after_destroy_commit :refresh_library_total_counts

  private

  def refresh_library_total_counts
    # 小説やライブラリごと削除された場合は更新先がないので何もしない
    library = novel&.library
    return unless library&.persisted?

    library.update_total_counts
  end
end
