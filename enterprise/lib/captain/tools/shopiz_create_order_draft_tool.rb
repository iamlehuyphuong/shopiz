# Public tool: Create a draft ConversationOrder natively within Shopiz.
class Captain::Tools::ShopizCreateOrderDraftTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::OrderMessageSendable

  description 'Create a draft order internally within Shopiz for the current contact. ' \
              'Items must be provided as a JSON array of objects. ' \
              'Order details are automatically sent to the customer.'
  param :product_items, type: 'string', desc: 'JSON array: [{"name":"Item 1","price":100000,"quantity":1,"id":"1"}]', required: true
  param :customer_note, type: 'string', desc: 'Optional note from the customer', required: false

  def perform(tool_context, product_items:, customer_note: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact

    items = parse_items(product_items)
    return 'Invalid product_items format' if items.nil? || items.empty?

    log_tool_usage('shopiz_create_order_draft', { items_count: items.size })

    order = create_draft_order(conversation, contact, items, customer_note)
    send_order_summary_message(conversation, order)
    format_draft_result(order)
  end

  private

  def parse_items(raw)
    parsed = JSON.parse(raw)
    return nil unless parsed.is_a?(Array)

    parsed.map do |i|
      {
        product_name: i['name'] || 'Unknown Item',
        product_id: i['id'] || 'custom',
        quantity: (i['quantity'] || i['qty'] || 1).to_i,
        unit_price: i['price'].to_f,
        product_source: 'shopiz'
      }
    end
  rescue JSON::ParserError
    nil
  end

  def create_draft_order(conversation, contact, items, customer_note)
    order = conversation.conversation_orders.new(
      account: conversation.account, contact: contact, status: :draft,
      customer_name: contact.name, customer_phone: contact.phone_number,
      customer_address: contact.additional_attributes&.dig('address'),
      customer_note: customer_note,
      external_source: 'shopiz'
    )
    items.each { |item| order.items.build(item) }
    order.save!
    order
  end

  def format_draft_result(order)
    lines = ["Local draft order ##{order.id} created. Order details sent to customer.\n", 'Items:']
    order.items.each { |item| lines << "  • #{item.product_name} × #{item.quantity} — #{format_currency(item.unit_price)} each" }
    lines << "\nTotal: #{format_currency(order.total_amount)}"
    lines << "Customer: #{order.customer_name} | #{order.customer_phone}"
    lines << "\nThis is a DRAFT order. Order summary has been sent to the customer."
    lines.join("\n")
  end

  def format_currency(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: 'đ', format: '%n%u', precision: 0)
  end
end
