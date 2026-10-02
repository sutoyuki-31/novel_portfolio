class LibrariesController < ApplicationController
  # 1. ログイン必須のページを指定（例: 新規作成や編集はログインが必要）
  before_action :authenticate_user!, except: [ :index ]
  # 2. 共通のレコード取得  set_libraryの中身を共通化
  before_action :set_library, only: [ :edit, :update, :destroy ]
  # 3. 閲覧・編集の権限チェック
  # before_action :ensure_visible# , only: [ :show ]
  before_action :ensure_correct_user, only: [ :edit, :update, :destroy ]

  def index
    @libraries = Library.all
      @librarie = Library.published
  end

  def list
    @libraries = current_user.libraries
    # Kaminariは params[:page] が nil の場合、自動的に1ページ目を表示します
    # @novels = @library.novels.page(params[:page]).per(10)
  end

  def show
    # 1. ログイン中のユーザーが所有するライブラリのみを検索（他人のものはこの時点でRecordNotFoundになる）
    @library = current_user.libraries.find(params[:id])
    @novels = @library.novels

    # 2. もし下書き（draft）かつ、本人が所有していない場合はエラーにする
    # (ただし、1行目で current_user の所有物しか取得していないため、本来この if 文自体が不要になります)
  end

  def edit
     @library = current_user.libraries.find(params[:id])
  end

  def new
    @library = Library.new
    # @libraries = current_user.libraries.build
  end
  def create
    @library = current_user.libraries.build(library_params)
    if @library.save
      # redirect_to library_novels_path(:library_id)
      redirect_to library_path(@library), notice: "小説を登録しました。", status: :see_other
    else
      # @novel = current_user.novels
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
       redirect_to library_path, notice: "削除しました", status: :see_other
    else
      flash.now[:alert] = @library.errors.full_messages.to_sentence
      render :show, status: :unprocessable_content
    end
  end

  private



  def ensure_correct_user
    # そもそも他人の記事を編集・削除しようとしたら404（またはトップへリダイレクト）
    if @library.user_id != current_user.id
      raise ActiveRecord::RecordNotFound
    end
  end

  def set_library
    @library = Library.find(params[:id])
  end


  def library_params
    params.require(:library).permit(:title, :synopsis)
  end
end
