class NovelsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]

  before_action :set_user_library, except: [ :index, :show ]
  before_action :set_public_library, only: [ :index, :show ]

  before_action :set_novel, only: [ :edit, :update, :destroy, :show ]
  def index
     # @library = Library.find(params[:library_id])
     @novel = Novel.published
    @novels = @library.novels.page(params[:page]).per(100)
     @comments = Comment.all
  end

  def show
   session[:init] = true
    current_session_id = session.id.to_s

    # 閲覧数の重複カウント防止（ログイン/ゲスト共通ロジック）
    conditions = NovelView.where(session_id: current_session_id, novel_id: @novel.id)

    if user_signed_in?
      conditions = conditions.or(NovelView.where(user_id: current_user.id, novel_id: @novel.id))
    end

    unless conditions.exists?
      NovelView.create(
        novel_id: @novel.id,
        session_id: current_session_id,
        user_id: current_user&.id
      )
    end

    # ページの前後へ
    @previous_novel = @novel.previous
    @next_novel = @novel.next
  end


  def mylit
  end

  def new
    @novel = Novel.new(library: @library)
    # @library = Library.find(params[:library_id])
    # @novel = @library.novels.build
  end

  def create
  @novel = Novel.new(novel_params)
  @novel.library = @library
  @novel.user = current_user
  @novel.status = :published

    if @novel.save
      # redirect_to library_novels_path(@library), notice: "小説を登録しました。", status: :see_other
      redirect_to library_path(@library), notice: "ページが作成されました。", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    # @novel = @library.novels.find(params[:id])
    if @novel.update(novel_params)
      # redirect_to library_novel_path(@library, @novel), notice: "更新しました"
      redirect_to library_path(@library), notice: "小説を登録しました。", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @novel.destroy

    # 削除後は、本の詳細画面（目次など）へリダイレクト
    redirect_to list_libraries_path, notice: "ページを削除し、以降のページ数を調整しました。", status: :see_other
  end

  def list
    # userが作成した作品を載せる
    @library = Library.all
  end


 private

  def set_public_library
    @library = Library.find(params[:library_id])
  end

  def set_user_library
   # current_user（ログイン中のユーザー）が持つライブラリから探すことで、
   # 不正なURL（他人のlibrary_id）を入力された場合のアクセスを自動でブロックします
   @library = current_user.libraries.find(params[:library_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定されたライブラリにアクセスする権限がありません。"
  end

  def set_novel
    # @library の中から探すことで、他人の小説へのアクセスを防ぐ
    @novel = @library.novels.find_by(page_number: params[:id])
    return if @novel

    # しおりの話が削除されていた場合など、存在しない話数は一覧に戻す
    # (edit/update/destroy でも使われるため、see_other を付けておく)
    redirect_to library_novels_path(@library),
                alert: "指定された話は見つかりませんでした。",
                status: :see_other
  end

  def novel_params
    params.require(:novel).permit(:story, :subtitle, :library_id, :status)
  end
end
