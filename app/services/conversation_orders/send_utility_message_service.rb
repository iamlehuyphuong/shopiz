class ConversationOrders::SendUtilityMessageService
  attr_reader :order, :conversation

  SUPPORTED_CHANNELS = %w[Channel::FacebookPage Channel::Telegram Channel::ZaloPersonal].freeze

  def initialize(order:, conversation:)
    @order = order
    @conversation = conversation
  end

  def perform
    return unless conversation.present? && order.present?
    return unless SUPPORTED_CHANNELS.include?(conversation.inbox.channel_type)

    content = generate_message_content
    return if content.blank?

    message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      private: false
    }

    if conversation.inbox.channel_type == 'Channel::FacebookPage'
      message_params[:content_attributes] = { message_tag: 'POST_PURCHASE_UPDATE' }
    end

    Messages::MessageBuilder.new(conversation.account, conversation, message_params).perform
  end

  private

  def generate_message_content
    I18n.t(
      'conversation_orders.utility_messages.status_update',
      order_id: order.id,
      status_label: status_label,
      total_amount: format_money(order.total_amount),
      default: nil
    )
  end

  def status_label
    I18n.t("conversation_orders.status.#{order.status}", default: order.status.humanize)
  end

  def format_money(amount)
    return '0' if amount.blank?

    # Simple formatting for now. Ideally this uses proper currency formatter based on account config.
    ActionController::Base.helpers.number_to_currency(amount, precision: 0, unit: 'đ', format: '%n %u')
  end
end
