class User < ApplicationRecord
  has_many :novels, dependent: :destroy
  has_many :libraries, dependent: :destroy
  has_many :likes, dependent: :destroy
  # 閲覧記録はゲストの記録と同じ扱い(user_id が null)で残す
  has_many :novel_views, dependent: :nullify

GUEST_EMAIL = "guest@example.com"

  def self.guest
    find_or_create_by!(email: GUEST_EMAIL) do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = "ゲスト" if user.respond_to?(:name=)
    end
  end

  def guest?
    email == GUEST_EMAIL
  end


  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
