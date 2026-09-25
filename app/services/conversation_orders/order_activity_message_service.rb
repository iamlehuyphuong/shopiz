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

    content, key, values = generate_activity_content
    return unless content

    ::Conversations::ActivityMessageJob.perform_later(conversation, activity_message_params(content, key, values))
  end

  private

  def generate_activity_content
    case action_type.to_sym
    when :created
      key = 'conversations.activity.orders.created'
      values = { order_id: order.id, user_name: user_name }
    when :pushed
      key = 'conversations.activity.orders.pushed'
      values = { order_id: order.id, platform: platform_label, external_id: order.external_order_id || 'N/A' }
    when :synced
      key = 'conversations.activity.orders.synced'
      values = { order_id: order.id, platform: platform_label, status: order.status }
    when :cancelled
      key = 'conversations.activity.orders.cancelled'
      values = { order_id: order.id, user_name: user_name }
    when :deleted
      key = 'conversations.activity.orders.deleted'
      values = { order_id: order.id, user_name: user_name }
    else
      return [nil, nil, nil]
    end

    # Keep a fallback evaluated content for DB, but the frontend will override it via the translation_key
    backend_translation_key = key.sub('conversations', 'conversation_orders')
    [I18n.t(backend_translation_key, **values), key, values]
  end

  def activity_message_params(content, translation_key, translation_values)
    params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    }
    if translation_key.present?
      params[:content_attributes] = {
        translation_key: translation_key,
        translation_values: translation_values
      }
    end

    params
  end

  def user_name
    user&.name || 'System'
  end

  def platform_label
    extra[:platform] || order.external_source || 'Unknown'
  end
end
