# Copilot tool: Push a confirmed ConversationOrder to Nhanh.vn via /api/order/add.
# Only confirmed orders can be pushed. Syncs external_order_id back to Shopiz.
class Captain::Tools::Copilot::Nhanhvn::PushOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Nhanhvn::Client

  def self.name
    'nhanhvn_push_order'
  end

  description 'Push a confirmed Shopiz order to Nhanh.vn. The order must be in confirmed status. ' \
              'Creates the order on Nhanh.vn and syncs the external order ID back.'
  param :conversation_order_id, type: :integer, desc: 'The Shopiz ConversationOrder ID to push', required: true

  def execute(conversation_order_id:)
    return 'Nhanh.vn integration is not connected' unless nhanhvn_active?

    order = find_order(conversation_order_id)
    return order_error(order, conversation_order_id) if order.is_a?(String)

    result = push_to_nhanhvn(order)
    return 'Failed to push order to Nhanh.vn. Check API logs.' if result.nil?

    nhanhvn_order_id = result.dig('data', 'orderId')
    sync_external_id(order, nhanhvn_order_id)
    format_success(order, nhanhvn_order_id, result)
  end

  def active?
    @user.present? && nhanhvn_active?
  end

  private

  def find_order(id)
    order = ConversationOrder.find_by(id: id, account_id: @assistant.account_id)
    return "Order ##{id} not found" if order.nil?
    return "Order ##{id} is already pushed (external_order_id: #{order.external_order_id})" if order.external_order_id.present?
    return "Order ##{id} must be confirmed before pushing. Current status: #{order.status}" unless order.confirmed?

    order
  end

  def order_error(result, id)
    result.is_a?(String) ? result : "Order ##{id} not found"
  end

  def push_to_nhanhvn(order)
    data = build_order_payload(order)
    nhanhvn_post('/api/order/add', data)
  end

  def build_order_payload(order)
    {
      id: order.id.to_s,
      type: 'Shipping',
      status: 'New',
      customerName: order.customer_name,
      customerMobile: order.customer_phone,
      customerAddress: order.customer_address,
      description: order.customer_note,
      productList: build_product_list(order)
    }
  end

  def build_product_list(order)
    order.items.map do |item|
      {
        idNhanh: item.product_id,
        name: item.product_name,
        quantity: item.quantity,
        price: item.unit_price.to_i
      }
    end
  end

  def sync_external_id(order, nhanhvn_order_id)
    order.update!(
      external_order_id: nhanhvn_order_id.to_s,
      external_source: 'nhanhvn',
      status: :processing
    )
  end

  def format_success(order, nhanhvn_order_id, result)
    carrier_code = result.dig('data', 'carrierCode')
    <<~RESPONSE.strip
      Order pushed to Nhanh.vn successfully!

      Shopiz Order: ##{order.id}
      Nhanh.vn Order ID: #{nhanhvn_order_id}
      Customer: #{order.customer_name} | #{order.customer_phone}
      Items: #{order.items.count} product(s)
      Total: #{format_vnd(order.total_amount)}
      #{carrier_code.present? ? "Tracking: #{carrier_code}" : ''}
    RESPONSE
  end
end
