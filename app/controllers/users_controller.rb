class UsersController < ApplicationController
def index
@users = User.all
end





def create
  @user = current_user.users.build(user_parms)
  if @user.save
    redirect_to @user, notice: "アカウントを作成しまた"
  else
    render :new
  end
end
end
