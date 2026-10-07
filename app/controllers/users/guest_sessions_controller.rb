# app/controllers/users/guest_sessions_controller.rb
class Users::GuestSessionsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def create
    user = User.guest
    sign_in user
    redirect_to myhome_users_path, notice: "ゲストとしてログインしました"
  end
end
