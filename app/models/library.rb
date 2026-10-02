class Library < ApplicationRecord
belongs_to :user
has_many :novels, dependent: :destroy
 # accepts_nested_attributes_for :novels
 #
 enum :status, { draft: 0, published: 1, archived: 2 }
  def self.status_options
    statuses.keys.map do |k|
      [ I18n.t("enums.library.status.#{k}"), k ]
    end
  end


enum :genre, { another: 0, reality: 1, highfantasy: 2,  lowfantasy: 3  }


 validates :title, presence: true, length: { maximum: 255 }
  validates :status, presence: true
end
