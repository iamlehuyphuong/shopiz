# Copilot tool: Push a confirmed ConversationOrder to Shopify.
class Captain::Tools::Copilot::Shopify::PushOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Shopify::Client

  def self.name
    'shopify_push_order'
  end

  description 'Push a confirmed Shopiz order to Shopify. Creates the order and syncs the external order ID.'
  param :conversation_order_id, type: :integer, desc: 'Shopiz ConversationOrder ID to push', required: true

  def execute(conversation_order_id:)
    return 'Shopify integration is not connected' unless shopify_active?

    order = find_order(conversation_order_id)
    return order if order.is_a?(String)

    result = push_to_shopify(order)
    return 'Failed to push order to Shopify.' if result.nil?

    shopify_order = result['order']
    return "Shopify error: #{result['errors']}" if shopify_order.nil?

    sync_external_id(order, shopify_order['id'])
    format_success(order, shopify_order)
  end

  def active?
    @user.present? && shopify_active?
  end

  private

  def find_order(id)
    order = ConversationOrder.find_by(id: id, account_id: @assistant.account_id)
    return "Order ##{id} not found" if order.nil?
    return "Order ##{id} already pushed (ID: #{order.external_order_id})" if order.external_order_id.present?
    return "Order ##{id} must be confirmed. Status: #{order.status}" unless order.confirmed?

    order
  end

  def push_to_shopify(order)
    shopify_post('orders.json', { order: build_payload(order) })
  end

  def build_payload(order)
    {
      line_items: order.items.map { |i| { variant_id: i.product_id, quantity: i.quantity, price: i.unit_price } },
      customer: { first_name: order.customer_name, phone: order.customer_phone },
      shipping_address: { address1: order.customer_address },
      note: order.customer_note,
      financial_status: 'pending'
    }
  end

  def sync_external_id(order, shopify_order_id)
    order.update!(external_order_id: shopify_order_id.to_s, external_source: 'shopify', status: :processing)
  end

  def format_success(order, shopify_order)
    <<~RESPONSE.strip
      Order pushed to Shopify!

      Shopiz Order: ##{order.id}
      Shopify Order: #{shopify_order['name'] || shopify_order['id']}
      Customer: #{order.customer_name} | #{order.customer_phone}
      Items: #{order.items.count} product(s)
      Total: #{format_currency(order.total_amount, 'VND')}
    RESPONSE
  end
end
