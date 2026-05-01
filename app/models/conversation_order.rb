class ConversationOrder < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :contact, optional: true
  has_many :items, class_name: 'ConversationOrderItem', dependent: :destroy_async

  accepts_nested_attributes_for :items, allow_destroy: true

  enum status: { draft: 0, confirmed: 1, processing: 2, shipped: 3, delivered: 4, cancelled: 5 }

  validates :account_id, presence: true
  validates :conversation_id, presence: true

  before_save :calculate_total_amount

  scope :ordered, -> { order(created_at: :desc) }

  private

  def calculate_total_amount
    self.total_amount = items.reject(&:marked_for_destruction?).sum { |item| item.quantity * item.unit_price }
  end
end
