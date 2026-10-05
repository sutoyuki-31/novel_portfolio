class User < ApplicationRecord
  has_many :novels, dependent: :destroy
  has_many :libraries, dependent: :destroy
  has_many :likes, dependent: :destroy
  # 閲覧記録はゲストの記録と同じ扱い(user_id が null)で残す
  has_many :novel_views, dependent: :nullify

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
