class LibrariesController < ApplicationController
  # 1. ログイン必須のページを指定（例: 新規作成や編集はログインが必要）
  before_action :authenticate_user!, except: [ :index, :show ]
  # 2. 共通のレコード取得  set_libraryの中身を共通化
  before_action :set_library, only: [ :show, :edit, :update, :destroy ]
  # 3. 閲覧・編集の権限チェック
  before_action :ensure_visible, only: [ :show ]
  before_action :ensure_correct_user, only: [ :edit, :update, :destroy ]

  def writing
     @library = Library.new
  end

  def list
     @library = Library.find(params[:id])
     page_number
    @libraries = Library.published.order(created_at: :desc)
  end

  def show
    @library = Library.find(params[:id])
    if @library.draft
      if current_user.nil? || @library.user_id != current_user.id
        raise ActiveRecord::RecordNotFound
      end
    end
  end

  def index
    @libraries = current_user.libraries
  end

  def novel
     @library = Library.find(params[:id])
    # @libraries = Library.all
    @libraries = Library.new
  end

def edit
end

  def create
    @library = current_user.libraries.build(library_params)
    if @library.save
      redirect_to libraries_path
    # redirect_to writing_path
    else
      # @novel = current_user.novels
      render :writing, status: :unprocessable_entity
    end
  end

  def update
    if @library.update(library_params)
      redirect_to novel_library_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @library.destroy
       redirect_to libraries_path, notice: "削除しました", status: :see_other
    else
      render :library, status: :unprocessable_entity
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
    params.require(:library).permit(:title, :synopsis, :novel_id, :story, :subtitle)
  end
end
