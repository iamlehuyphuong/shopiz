# Service to create activity messages in the conversation timeline
# when order lifecycle events occur (created, pushed, synced, cancelled, deleted).
# Follows the Linear::ActivityMessageService pattern.
class ConversationOrders::OrderActivityMessageService
  attr_reader :conversation, :order, :action_type, :user, :extra

  def initialize(conversation:, order:, action_type:, user:, extra: {})
    @conversation = conversation
    @order = order
    @action_type = action_type
    @user = user
    @extra = extra
  end

  def perform
    return unless conversation && order

    content = generate_activity_content
    return unless content

    ::Conversations::ActivityMessageJob.perform_later(conversation, activity_message_params(content))
  end

  private

  def generate_activity_content
    case action_type.to_sym
    when :created
      I18n.t('conversation_orders.activity.created',
             order_id: order.id, user_name: user_name)
    when :pushed
      I18n.t('conversation_orders.activity.pushed',
             order_id: order.id, platform: platform_label,
             external_id: order.external_order_id || 'N/A')
    when :synced
      I18n.t('conversation_orders.activity.synced',
             order_id: order.id, platform: platform_label,
             status: order.status)
    when :cancelled
      I18n.t('conversation_orders.activity.cancelled',
             order_id: order.id, user_name: user_name)
    when :deleted
      I18n.t('conversation_orders.activity.deleted',
             order_id: order.id, user_name: user_name)
    end
  end

  def activity_message_params(content)
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    }
  end

  def user_name
    user&.name || 'System'
  end

  def platform_label
    extra[:platform] || order.external_source || 'Unknown'
  end
end
