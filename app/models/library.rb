class Library < ApplicationRecord
  belongs_to :user
  has_many :novels, dependent: :destroy
  # likes テーブルには library_id がないため、novels 経由で取得する
  has_many :likes, through: :novels

  # 列挙型（Enum）の定義
  enum :status, { draft: 0, published: 1, archived: 2 }
  enum :genre, { another: 0, reality: 1, highfantasy: 2, lowfantasy: 3 }

  # バリデーション
  validates :title, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :genre, presence: true

  # クラスメソッド
  def self.status_options
    # 翻訳のフォールバック（default: k）を設定しておくと翻訳ファイルがない時も安心です
    statuses.keys.map do |k|
      [ I18n.t("enums.library.status.#{k}", default: k), k ]
    end
  end

  def self.search(search_word)
    if search_word.present?
      where("title LIKE ?", "%#{search_word}%")
    else
      all
    end
  end

  # 集計値を実データから再計算する
  # update だとタイトルなどのバリデーションが走り、古いデータで失敗するため
  # カウンターのカラムだけを update_columns で直接更新する
  def update_total_counts
    update_columns(
      total_views_count: novels.sum(:view_counts_count),
      total_likes_count: likes.count
    )
  end

  # インスタンスメソッド
  # 「最初のページ」は作成日時ではなく page_number で決める
  def first_novel_id
    if novels.loaded?
      # コントローラー側で includes(:novels) されている場合は、
      # メモリ上の配列から探す（追加のSQLは0回）
      novels.min_by { |novel| novel.page_number.to_i }&.id
    else
      # 事前ロードされていない場合は、IDだけを取得する
      novels.order(:page_number).pick(:id)
    end
  end
end
