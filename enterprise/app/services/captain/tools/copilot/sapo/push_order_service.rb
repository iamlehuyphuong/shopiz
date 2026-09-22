# Copilot tool: Push a confirmed ConversationOrder to Sapo via orders.json API.
class Captain::Tools::Copilot::Sapo::PushOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Sapo::Client

  def self.name
    'sapo_push_order'
  end

  description 'Push a confirmed Shopiz order to Sapo. Creates the order and syncs the external order ID.'
  param :conversation_order_id, type: :integer, desc: 'Shopiz ConversationOrder ID to push', required: true

  def execute(conversation_order_id:)
    return 'Sapo integration is not connected' unless sapo_active?

    order = find_order(conversation_order_id)
    return order if order.is_a?(String)

    result = push_to_sapo(order)
    return 'Failed to push order to Sapo.' if result.nil?

    sapo_order = result['order']
    return 'Sapo returned an error.' if sapo_order.nil?

    sync_external_id(order, sapo_order['id'])
    format_success(order, sapo_order)
  end

  def active?
    @user.present? && sapo_active?
  end

  private

  def find_order(id)
    order = ConversationOrder.find_by(id: id, account_id: @assistant.account_id)
    return "Order ##{id} not found" if order.nil?
    return "Order ##{id} already pushed (ID: #{order.external_order_id})" if order.external_order_id.present?
    return "Order ##{id} must be confirmed first. Status: #{order.status}" unless order.confirmed?

    order
  end

  def push_to_sapo(order)
    sapo_post('orders.json', { order: build_payload(order) })
  end

  def build_payload(order)
    {
      line_items: order.items.map { |item| { variant_id: item.product_id, quantity: item.quantity, price: item.unit_price } },
      customer: { first_name: order.customer_name, phone: order.customer_phone },
      shipping_address: { address1: order.customer_address },
      note: order.customer_note
    }
  end

  def sync_external_id(order, sapo_order_id)
    order.update!(external_order_id: sapo_order_id.to_s, external_source: 'sapo', status: :processing)
  end

  def format_success(order, sapo_order)
    <<~RESPONSE.strip
      Order pushed to Sapo!

      Shopiz Order: ##{order.id}
      Sapo Order: ##{sapo_order['order_number']} (ID: #{sapo_order['id']})
      Customer: #{order.customer_name} | #{order.customer_phone}
      Items: #{order.items.count} product(s)
      Total: #{format_sapo_currency(order.total_amount)}
    RESPONSE
  end
end
