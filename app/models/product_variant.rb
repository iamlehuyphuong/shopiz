class ProductVariant < ApplicationRecord
  belongs_to :account
  belongs_to :product

  validates :name, presence: true
  validates :sku, uniqueness: { scope: :account_id }, allow_blank: true
end
