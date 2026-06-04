# Copilot tool: Push a confirmed ConversationOrder to WooCommerce.
class Captain::Tools::Copilot::WoocommercePushOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::WoocommerceClient

  def self.name
    'woocommerce_push_order'
  end

  description 'Push a confirmed Shopiz order to WooCommerce and sync the external order ID.'
  param :conversation_order_id, type: :integer, desc: 'Shopiz ConversationOrder ID to push', required: true

  def execute(conversation_order_id:)
    return 'WooCommerce integration is not connected' unless woocommerce_active?

    order = find_order(conversation_order_id)
    return order if order.is_a?(String)

    result = push_to_woo(order)
    return 'Failed to push order to WooCommerce.' if result.nil?
    return "WooCommerce error: #{result['message']}" if result['id'].nil?

    sync_external_id(order, result['id'])
    format_success(order, result)
  end

  def active?
    @user.present? && woocommerce_active?
  end

  private

  def find_order(id)
    order = ConversationOrder.find_by(id: id, account_id: @assistant.account_id)
    return "Order ##{id} not found" if order.nil?
    return "Order ##{id} already pushed (ID: #{order.external_order_id})" if order.external_order_id.present?
    return "Order ##{id} must be confirmed. Status: #{order.status}" unless order.confirmed?

    order
  end

  def push_to_woo(order)
    woocommerce_post('orders', build_payload(order))
  end

  def build_payload(order)
    {
      line_items: order.items.map { |i| { product_id: i.product_id.to_i, quantity: i.quantity } },
      billing: { first_name: order.customer_name, phone: order.customer_phone, address_1: order.customer_address },
      shipping: { first_name: order.customer_name, address_1: order.customer_address },
      customer_note: order.customer_note,
      status: 'processing'
    }
  end

  def sync_external_id(order, woo_order_id)
    order.update!(external_order_id: woo_order_id.to_s, external_source: 'woocommerce', status: :processing)
  end

  def format_success(order, woo_order)
    <<~RESPONSE.strip
      Order pushed to WooCommerce!

      Shopiz Order: ##{order.id}
      WooCommerce Order: ##{woo_order['number']} (ID: #{woo_order['id']})
      Customer: #{order.customer_name} | #{order.customer_phone}
      Items: #{order.items.count} product(s)
      Total: #{format_woo_currency(order.total_amount)}
    RESPONSE
  end
end
