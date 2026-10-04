class LibrariesController < ApplicationController
  # 1. ログイン必須のページを指定
  before_action :authenticate_user!, except: [ :index, :history ]
  # 2. 共通のレコード取得
  before_action :set_library, only: [ :show, :edit, :update, :destroy ]
  # 3. 閲覧・編集の権限チェック
  before_action :ensure_correct_user, only: [ :edit, :update, :destroy ]
  # show用の権限チェック（他人の下書きを見せない等があればここで制御）
  before_action :ensure_visible_library, only: [ :show ]

  def index
    # 1. ベースデータの取得 💡 ユーザーの事前読み込み ＋ 小説のいいね数を一括集計
    base_query = Library.published
                      .includes(:user)
                      .left_joins(novels: :likes)
                      .group("libraries.id")
                      .select("libraries.*", "COUNT(likes.id) AS count_of_likes")

    # 2. テキストキーワード（タイトル・キーワード）で絞り込み
    if params[:keyword].present?
      keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:keyword])}%"
      # GROUP BY句があるため、HAVINGではなくWHEREで絞り込むために unscoped から where を繋ぐか、
      # またはそのままwhereを繋げば、ActiveRecordが自動的に適切なSQL（WHERE節）に組み立ててくれます。
      base_query = base_query.where("libraries.title LIKE ? OR libraries.tag LIKE ?", keyword, keyword)
    end

    # 3. enumのジャンル（複数選択対応）でさらに絞り込み
    if params[:genres].present?
      base_query = base_query.where(genre: params[:genres])
    end

    # 最終的な一覧用データを代入
    @libraries = base_query

    # 4. ランキングの取得 💡 こちらも同様にいいね数を集計して上位10件を取得
    @library_ranking = Library.published # ランキングも公開中(published)のみにする場合はこちら
                            .includes(:user)
                            .left_joins(novels: :likes)
                            .group("libraries.id")
                            .select("libraries.*", "COUNT(likes.id) AS count_of_likes")
                            .order(total_views_count: :desc)
                            .limit(10)
  end

  def list
    # ログインユーザーのライブラリ一覧（マイページ用など）
    @libraries = current_user.libraries
  end

  def show
    # before_action で @library は取得済み
    @novels = @library.novels
  end

  def edit
    # before_action で @library は取得済みのため、中身は空でOK
  end

  def new
    @library = Library.new
  end

  def create
    @library = current_user.libraries.build(library_params)
    if @library.save
      redirect_to library_path(@library), notice: "小説を登録しました。", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @library.update(library_params)
      redirect_to library_path(@library), notice: "更新しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @library.destroy
       # 💡 削除後は詳細(library_path)ではなく、一覧(libraries_path)へリダイレクト
       redirect_to libraries_path, notice: "削除しました", status: :see_other
    else
      flash.now[:alert] = @library.errors.full_messages.to_sentence
      render :show, status: :unprocessable_content
    end
  end

  def history
    respond_to do |format|
      format.html do
        # 1. 最初は空のHTML画面を表示する
      end

      format.json do
        # 2. 安全対策：数値（ID）のみの配列に絞り込む
        library_ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)

        if library_ids.empty?
          render json: []
          return
        end

        @libraries = Library.includes(:novels).where(id: library_ids)

        render json: @libraries.as_json(
          only: [ :id, :title, :synopsis ],
          methods: [ :first_novel_id ]
        )
      end
    end
  end

  private

  def set_library
    @library = Library.find(params[:id])
  end

  def ensure_correct_user
    # 💡 自身の所有していないライブラリであれば 404 エラーにする
    if @library.user_id != current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end

  def ensure_visible_library
    # 💡 もし下書き（draft）状態、かつ本人のものでなければ閲覧不可にする設定例
    # (Libraryモデルに status カラムがあり、下書きが "draft" の場合)
    if @library.respond_to?(:status) && @library.status == "draft" && @library.user_id != current_user&.id
      raise ActiveRecord::RecordNotFound
    end
  end

  def library_params
    params.require(:library).permit(:title, :synopsis, :tag, :genre, :status)
  end
end
