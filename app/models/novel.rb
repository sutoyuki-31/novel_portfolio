class Novel < ApplicationRecord
belongs_to :user
belongs_to :library
before_validation :assign_page_number, on: :create
after_destroy :renumber_subsequent_pages

  def to_param
    page_number.to_s
  end

  def previous
    library.novels.find_by(page_number: page_number - 1)
  end

  # max_page から page_number に修正
  def next
    library.novels.find_by(page_number: page_number + 1)
  end

  validates :subtitle, presence: true, length: { maximum: 255 }
  validates :story, presence: true
  validates :status, presence: true
  validates :page_number, uniqueness: { scope: :library_id }, allow_blank: true
  # Enumの設定
  enum :status, { draft: 0, published: 1, archived: 2 }

  private

  def renumber_subsequent_pages
    # 同じ本（library）に紐づく、削除されたページ（自分自身）より後ろのページを取得
    # 例：3ページ目が消されたら、4ページ目以降が対象
    subsequent_pages = library.novels.where("page_number > ?", page_number)

    # 該当するページの page_number をすべて -1 する
    # update_all を使うことで、1回のSQLで高速に一括更新できます
    subsequent_pages.update_all("page_number = page_number - 1")
  end

  def assign_page_number
    return if library_id.blank?

    # .to_i を使うことで、nil の場合は 0 になり、+1 されて 1 になります（ロジックの共通化）
    max_page = Novel.where(library_id: library_id).maximum(:page_number).to_i
    self.page_number = max_page + 1
  end
end
