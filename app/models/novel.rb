class Novel < ApplicationRecord
  belongs_to :user
  belongs_to :library
  has_many :likes, dependent: :destroy
  has_many :novel_views, dependent: :destroy

  # Enumの設定
  enum :status, { draft: 0, published: 1, archived: 2 }

  validates :subtitle, presence: true, length: { maximum: 255 }
  validates :story, presence: true
  validates :status, presence: true
  validates :page_number, uniqueness: { scope: :library_id }, allow_blank: true

  before_validation :assign_page_number, on: :create
  after_destroy :renumber_subsequent_pages
  # 閲覧数のカウンターキャッシュはコールバックを通らないため、after_save では更新できない
  # (閲覧数の集計は NovelView 側で行う)。小説の削除で減る分だけをここで再計算する
  after_destroy_commit :update_library_total_counts

  def to_param
    page_number.to_s
  end

  def update_library_total_counts
    # ライブラリごと削除された場合は更新先がないので何もしない
    return unless library&.persisted?

    library.update_total_counts
  end

  def previous
    library.novels.find_by(page_number: page_number - 1)
  end

  def next
    library.novels.find_by(page_number: page_number + 1)
  end

  def liked_by?(user)
    return false unless user # ログアウト時(nil)の対策
    likes.exists?(user_id: user.id)
  end

  private

  def renumber_subsequent_pages
    # ライブラリごと削除される場合は、詰め直しは不要
    return if destroyed_by_association&.active_record == Library
    return if library.nil?

    # 小さいページ番号から順に1つずつ詰める。
    # 一括 UPDATE (page_number = page_number - 1) だと、行の処理順によって
    # ユニーク制約 [library_id, page_number] に一時的に衝突する恐れがあるため
    library.novels.where("page_number > ?", page_number).order(:page_number).each do |novel|
      novel.update_columns(page_number: novel.page_number - 1)
    end
  end

  def assign_page_number
    return if library_id.blank?

    # maximum が nil の場合は .to_i で 0 になり、+1 されて 1 になる
    max_page = Novel.where(library_id: library_id).maximum(:page_number).to_i
    self.page_number = max_page + 1
  end
end
