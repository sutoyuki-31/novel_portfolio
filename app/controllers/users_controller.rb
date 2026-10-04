class UsersController < ApplicationController
  # ログイン必須にする場合はアクションを追加（deviseの例）
  before_action :authenticate_user!, only: [ :myhome, :create, :edit, :update ]

  def index
    # 👥 もし管理画面やユーザー一覧で使うなら残しますが、不要なら削除してOKです
    @users = User.all

    # ビューの <%= render "users/user-tag", user: @user %> で使う変数を定義
    @user = current_user

  @library_ranking = Library.includes(:user)
                              .where("total_views_count > ?", 0)
                              .order(total_views_count: :desc)
                              .limit(10)

    # 🏆 1PV以上の小説を閲覧数順にトップ10取得（N+1対策済み）
    @novel_ranking = Novel.includes(:library)
                          .where("view_counts_count > ?", 0)
                          .order(view_counts_count: :desc)
                          .limit(10)
  end

  def myhome
    # マイページ表示用にログインユーザーをセット
    @user = current_user
     @libraries = current_user.libraries
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: "アカウントを作成しました"
    else
      render :new
    end
  end

  def edit
    @user = current_user
  end

  # 📝 実際に名前を更新するアクション
  def update
    @user = current_user

    if @user.update(user_params)
      # 更新に成功したらマイページ（myhome）へリダイレクト
      redirect_to myhome_users_path, notice: "名前を変更しました"
    else
      # バリデーションエラーなどがあれば編集画面を再表示
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end
end
