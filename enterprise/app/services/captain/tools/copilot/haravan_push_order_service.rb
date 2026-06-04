# Copilot tool: Push a confirmed ConversationOrder to Haravan.
class Captain::Tools::Copilot::HaravanPushOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::HaravanClient

  def self.name
    'haravan_push_order'
  end

  description 'Push a confirmed Shopiz order to Haravan. Creates the order and syncs the external order ID.'
  param :conversation_order_id, type: :integer, desc: 'Shopiz ConversationOrder ID to push', required: true

  def execute(conversation_order_id:)
    return 'Haravan integration is not connected' unless haravan_active?

    order = find_order(conversation_order_id)
    return order if order.is_a?(String)

    result = push_to_haravan(order)
    return 'Failed to push order to Haravan.' if result.nil?

    haravan_order = result['order']
    return 'Haravan returned an error.' if haravan_order.nil?

    sync_external_id(order, haravan_order['id'])
    format_success(order, haravan_order)
  end

  def active?
    @user.present? && haravan_active?
  end

  private

  def find_order(id)
    order = ConversationOrder.find_by(id: id, account_id: @assistant.account_id)
    return "Order ##{id} not found" if order.nil?
    return "Order ##{id} already pushed (ID: #{order.external_order_id})" if order.external_order_id.present?
    return "Order ##{id} must be confirmed first. Status: #{order.status}" unless order.confirmed?

    order
  end

  def push_to_haravan(order)
    haravan_post('orders.json', { order: build_payload(order) })
  end

  def build_payload(order)
    {
      line_items: order.items.map { |item| { variant_id: item.product_id, quantity: item.quantity, price: item.unit_price } },
      customer: { first_name: order.customer_name, phone: order.customer_phone },
      shipping_address: { address1: order.customer_address },
      note: order.customer_note
    }
  end

  def sync_external_id(order, haravan_order_id)
    order.update!(external_order_id: haravan_order_id.to_s, external_source: 'haravan', status: :processing)
  end

  def format_success(order, haravan_order)
    <<~RESPONSE.strip
      ✅ Order pushed to Haravan!

      Shopiz Order: ##{order.id}
      Haravan Order: #{haravan_order['name'] || haravan_order['id']}
      Customer: #{order.customer_name} | #{order.customer_phone}
      Items: #{order.items.count} product(s)
      Total: #{format_haravan_currency(order.total_amount)}
    RESPONSE
  end
end
