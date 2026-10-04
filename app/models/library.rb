class Library < ApplicationRecord
  belongs_to :user
  has_many :novels, dependent: :destroy
  has_many :likes
  # 列挙型（Enum）の定義
  enum :status, { draft: 0, published: 1, archived: 2 }
  # genreのカンマが重複していた部分（,,）を修正
  enum :genre, { another: 0, reality: 1, highfantasy: 2, lowfantasy: 3 }

  # バリデーション
  validates :title, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  # genreも選択必須にする場合は追加（初期値の include_blank に対応）
  validates :genre, presence: true

  # クラスメソッド
  def self.status_options
    # 翻訳のフォールバック（default: k）を設定しておくと翻訳ファイルがない時も安心です
    statuses.keys.map do |k|
      [ I18n.t("enums.library.status.#{k}", default: k), k ]
    end
  end


  def update_total_counts
    update(
      total_views_count: novels.sum(:view_counts_count),
      total_likes_count: novels.joins(:likes).count # もしくは各小説にお気に入りカウンターキャッシュがあるなら novels.sum(:likes_count)
    )
  end

  # インスタンスメソッド
  # インスタンスメソッド
  def first_novel_id
    if novels.loaded?
      # 💡 コントローラー側で includes(:novels) されている場合、
      # メモリ上の配列を Ruby 側でソートして先頭のIDを返す（追加のSQLは0回）
      novels.sort_by(&:created_at).first&.id
    else
      # 事前ロードされていない場合は、最小限のクエリ（pick）でIDのみを取得する
      novels.order(:created_at).pick(:id)
    end
  end

  def self.search(search_word)
    if search_word.present?
      where("title LIKE ?", "%#{search_word}%")
    else
      all
    end
  end
end
