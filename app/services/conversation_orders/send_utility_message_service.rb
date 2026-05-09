class ConversationOrders::SendUtilityMessageService
  attr_reader :order, :conversation

  SUPPORTED_CHANNELS = %w[Channel::FacebookPage Channel::Telegram Channel::ZaloPersonal Channel::ZaloOa Channel::Whatsapp Channel::Instagram
                          Channel::Tiktok Channel::TiktokShop Channel::Line].freeze

  def initialize(order:, conversation:)
    @order = order
    @conversation = conversation
  end

  def perform
    return unless conversation.present? && order.present?
    return unless SUPPORTED_CHANNELS.include?(conversation.inbox.channel_type)

    if send_mapped_template_message
      return # Handled by template
    end

    content = generate_message_content
    return if content.blank?

    message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: 'outgoing',
      content: content,
      private: false
    }

    message_params[:content_attributes] = { message_tag: 'POST_PURCHASE_UPDATE' } if conversation.inbox.channel_type == 'Channel::FacebookPage'

    Messages::MessageBuilder.new(nil, conversation, message_params).perform
  end

  private

  def send_mapped_template_message
    return false unless %w[Channel::ZaloOa Channel::Whatsapp].include?(conversation.inbox.channel_type)

    mapping = conversation.inbox.settings.dig('order_template_mapping', order.status)
    return false if mapping.blank?

    template_id = mapping['template_id']
    variables_mapping = mapping['variables'] || {}

    variables = variables_mapping.transform_values do |sys_var|
      resolve_variable(sys_var).to_s
    end

    if conversation.inbox.channel_type == 'Channel::ZaloOa'
      template = ZaloMessageTemplate.find_by(id: template_id, channel_id: conversation.inbox.channel_id)
      return false unless template

      Zalo::TransactionMessageService.new(
        channel: conversation.inbox.channel,
        user_id: conversation.contact_inbox.source_id,
        template: template,
        variables: variables
      ).perform
      true
    elsif conversation.inbox.channel_type == 'Channel::Whatsapp'
      template = MessageTemplate.find_by(id: template_id, channel_type: 'Channel::Whatsapp', inbox_id: conversation.inbox_id)
      return false unless template

      message_params = {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: 'outgoing',
        content: template.name,
        private: false,
        additional_attributes: {
          template_params: {
            name: template.name,
            category: template.category,
            language: template.language,
            processed_params: variables
          }
        }
      }
      Messages::MessageBuilder.new(conversation.account, conversation, message_params).perform
      true
    end
  end

  def generate_message_content
    templates = conversation.account.settings['sales_order_notification_templates'] || {}
    template = templates[order.status]

    if template.present?
      template.gsub('%<customer_name>s', resolve_variable('customer_name').to_s)
              .gsub('%<fanpage_name>s', resolve_variable('fanpage_name').to_s)
              .gsub('%<order_id>s', resolve_variable('order_id').to_s)
              .gsub('%<status_label>s', resolve_variable('status_label').to_s)
              .gsub('%<total_amount>s', resolve_variable('total_amount').to_s)
    else
      I18n.t(
        'conversation_orders.utility_messages.status_update',
        order_id: order.id,
        status_label: status_label,
        total_amount: format_money(order.total_amount),
        customer_name: resolve_variable('customer_name'),
        fanpage_name: resolve_variable('fanpage_name'),
        default: nil
      )
    end
  end

  def resolve_variable(sys_var)
    case sys_var
    when 'customer.name', 'customer_name'
      conversation.contact.name
    when 'fanpage.name', 'fanpage_name'
      conversation.inbox.name
    when 'order.id', 'order_id'
      order.id
    when 'order.total_amount', 'total_amount'
      format_money(order.total_amount)
    when 'status_label'
      status_label
    else
      ''
    end
  end

  def status_label
    I18n.t("conversation_orders.status.#{order.status}", default: order.status.humanize)
  end

  def format_money(amount)
    return '0' if amount.blank?

    ActionController::Base.helpers.number_to_currency(amount, precision: 0, unit: 'đ', format: '%n %u')
  end
end
