class ConversationOrder < ApplicationRecord
  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true
  has_many :items, class_name: 'ConversationOrderItem', dependent: :destroy_async

  accepts_nested_attributes_for :items, allow_destroy: true

  enum status: { draft: 0, confirmed: 1, processing: 2, shipped: 3, delivered: 4, cancelled: 5, returned: 6 }
  enum payment_status: { unpaid: 'unpaid', paid: 'paid', partially_refunded: 'partially_refunded', failed: 'failed', expired: 'expired' }

  validates :account_id, presence: true
  validates :conversation_id, presence: true, if: -> { contact_id.blank? }
  validates :contact_id, presence: true, if: -> { conversation_id.blank? }

  before_save :calculate_total_amount
  after_commit :enqueue_status_update_message, on: :update
  after_commit :enqueue_payment_generation, on: :update

  scope :ordered, -> { order(created_at: :desc) }

  private

  def calculate_total_amount
    subtotal = items.reject(&:marked_for_destruction?).sum { |item| item.quantity * item.unit_price }
    self.total_amount = subtotal + (shipping_fee || 0.0) + (tax || 0.0) - (discount_amount || 0.0)
  end

  def enqueue_payment_generation
    return unless saved_change_to_status?
    return unless status == 'confirmed'
    return unless %w[sepay payos tingee].include?(payment_method)
    return unless unpaid?

    Payments::GeneratePaymentJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("ConversationOrder#enqueue_payment_generation failed for order #{id}: #{e.message}")
  end

  def enqueue_status_update_message
    return unless saved_change_to_status?
    return unless %w[confirmed processing shipped delivered cancelled returned].include?(status)

    ConversationOrders::SendStatusUpdateJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("ConversationOrder#enqueue_status_update_message failed for order #{id}: #{e.message}")
  end
end
