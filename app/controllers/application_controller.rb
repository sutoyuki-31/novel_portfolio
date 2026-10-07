class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

 before_action :configure_permitted_parameters, if: :devise_controller?
  # 例: プロフィール編集やパスワード変更などに適用
  # before_action :reject_guest!, only: [ :edit, :update, :destroy ]

  def configure_permitted_parameters
    # ユーザー登録（サインアップ）時に name カラムの保存を許可する
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])

    # アカウント編集時にも name の変更を許可する場合は以下を追加
    #  devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

def reject_guest!
  if current_user&.guest?
    redirect_to root_path, alert: "ゲストユーザーは変更できません"
  end
end

   def after_sign_in_path_for(resource)
   myhome_users_path
   end
end
