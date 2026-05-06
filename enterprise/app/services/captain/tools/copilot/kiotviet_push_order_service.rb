# Copilot tool: Push a confirmed ConversationOrder to KiotViet as a real order.
# Links the Shopiz order to KiotViet via external_order_id and external_source.
class Captain::Tools::Copilot::KiotvietPushOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::KiotvietClient

  def self.name
    'kiotviet_push_order'
  end

  description 'Push a confirmed Shopiz order to KiotViet as a real order. ' \
              'The order must be in "confirmed" status. Creates or matches the customer on KiotViet ' \
              'and syncs all order items.'
  param :conversation_order_id, type: :integer, desc: 'Shopiz ConversationOrder ID to push to KiotViet', required: true

  def execute(conversation_order_id:)
    return 'KiotViet integration is not connected' unless kiotviet_active?

    order = find_order(conversation_order_id)
    return validate_order(order)[:error] if validate_order(order)[:error]

    push_and_sync(order)
  end

  def active?
    @user.present? && kiotviet_active?
  end

  private

  def find_order(id)
    ConversationOrder.where(account_id: @assistant.account_id).find_by(id: id)
  end

  def validate_order(order)
    return { error: 'Order not found' } if order.nil?
    return { error: "Order must be in 'confirmed' status to push to KiotViet (current: #{order.status})" } unless order.confirmed?
    return { error: 'Order has already been pushed to KiotViet' } if order.external_order_id.present?

    { error: nil }
  end

  def push_and_sync(order)
    customer_id = resolve_kiotviet_customer(order)
    kv_order = push_to_kiotviet(order, customer_id)

    return 'Failed to create order on KiotViet. Please check the product codes and try again.' if kv_order.nil?
    return "KiotViet error: #{kv_order.dig('responseStatus', 'message') || 'Unknown error'}" if kv_order['responseStatus'].present?

    save_external_reference(order, kv_order)
    format_success(order, kv_order)
  end

  def resolve_kiotviet_customer(order)
    existing = find_existing_customer(order.customer_phone)
    return existing['id'] if existing.present?

    create_kiotviet_customer(order)
  end

  def find_existing_customer(phone)
    return nil if phone.blank?

    result = kiotviet_get('customers', { contactNumber: phone, pageSize: 1 })
    result&.dig('data')&.first
  end

  def create_kiotviet_customer(order)
    new_customer = kiotviet_post('customers', {
                                   name: order.customer_name || 'Unknown',
                                   contactNumber: order.customer_phone,
                                   address: order.customer_address
                                 })
    new_customer&.dig('id')
  end

  def push_to_kiotviet(order, customer_id)
    body = { customerId: customer_id, orderDetails: build_order_details(order), description: order.customer_note }
    body[:deliveryDetail] = build_delivery_detail(order) if order.customer_address.present?
    kiotviet_post('orders', body)
  end

  def build_order_details(order)
    order.items.map do |item|
      { productId: item.product_id.to_i, quantity: item.quantity, price: item.unit_price.to_f, productName: item.product_name }
    end
  end

  def build_delivery_detail(order)
    { receiver: order.customer_name, contactNumber: order.customer_phone, address: order.customer_address, status: 3 }
  end

  def save_external_reference(order, kv_order)
    order.update!(external_order_id: kv_order['code'] || kv_order['id'].to_s, external_source: 'kiotviet')
  end

  def format_success(order, kv_order)
    <<~RESULT.strip
      ✅ Order pushed to KiotViet successfully!

      Shopiz Order: ##{order.id}
      KiotViet Order: #{kv_order['code'] || kv_order['id']}
      Customer: #{order.customer_name}
      Items: #{order.items.count} product(s)
      Total: #{format_vnd(order.total_amount)}

      The order is now synced. Updates on KiotViet will be reflected in the order code.
    RESULT
  end
end
