class Captain::Tools::SendProductInfoTool < Captain::Tools::BasePublicTool
  description 'Send product information to the customer in the conversation as a text message. ' \
              'Use after searching for products to share details with the customer.'

  param :product_ids, type: 'string', desc: 'Comma-separated product IDs to send info for (e.g. "123,456")', required: true

  def perform(tool_context, product_ids:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    ids = product_ids.split(',').map(&:strip).reject(&:blank?)
    return 'At least one product ID is required' if ids.empty?

    products = account_scoped(Product).where(id: ids, status: :active).limit(5)
    return 'No active products found with the provided IDs' if products.empty?

    log_tool_usage('send_product_info', { conversation_id: conversation.id, product_ids: ids })

    content = format_product_message(conversation, products)
    send_outgoing_message(conversation, content)

    "Product information sent to customer (#{products.size} product(s))"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to send product information'
  end

  private

  def permissions
    %w[conversation_manage]
  end

  def format_product_message(conversation, products)
    locale = conversation.contact&.additional_attributes&.dig('locale') || conversation.account.locale || I18n.default_locale

    I18n.with_locale(locale) do
      lines = [I18n.t('captain.tools.send_product_info.header', default: "Product information:\n")]

      products.each_with_index do |product, index|
        lines << "#{index + 1}. #{product.name}"
        lines << "   #{I18n.t('captain.tools.send_product_info.price', default: 'Price')}: #{format_money(product.price)}"
        if product.inventory_quantity.to_i.positive?
          lines << "   #{I18n.t('captain.tools.send_product_info.stock',
                                default: 'In stock')}: #{product.inventory_quantity.to_i}"
        end
        lines << "   SKU: #{product.sku}" if product.sku.present?
        lines << "   #{product.description.truncate(120)}" if product.description.present?
        lines << '' # blank line between products
      end

      lines.join("\n")
    end
  end

  def format_money(amount)
    return I18n.t('captain.tools.send_product_info.contact_for_price', default: 'Contact') if amount.blank? || amount.zero?

    ActionController::Base.helpers.number_to_currency(amount, precision: 0, unit: 'đ', format: '%n %u')
  end

  def send_outgoing_message(conversation, content)
    message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: 'outgoing',
      content: content,
      private: false
    }
    Messages::MessageBuilder.new(nil, conversation, message_params).perform
  end
end
