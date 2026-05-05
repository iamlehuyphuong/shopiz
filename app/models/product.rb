class Product < ApplicationRecord
  belongs_to :account
  has_many :product_variants, dependent: :destroy
  
  enum status: { active: 0, archived: 1, draft: 2 }

  validates :name, presence: true
  validates :sku, uniqueness: { scope: :account_id }, allow_blank: true
end
