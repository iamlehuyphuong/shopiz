# Proxy for WooCommerce Order API.
# WooCommerce REST API v3: POST /orders, GET /orders/{id}
class ConversationOrders::WoocommerceProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::WoocommerceClient

  def create_order(payload)
    woocommerce_post('orders', payload)
  end

  def fetch_order(order_id)
    woocommerce_get("orders/#{order_id}")
  end

  def map_status(raw_status)
    # WooCommerce: pending, processing, on-hold, completed, cancelled, refunded, failed
    case raw_status.to_s.downcase
    when 'pending', 'on-hold' then :confirmed
    when 'processing' then :processing
    when 'completed' then :delivered
    when 'cancelled', 'refunded', 'failed' then :cancelled
    end
  end

  def extract_order_id(result)
    result&.dig('id')&.to_s
  end

  def extract_error(result)
    result&.dig('message') || super
  end
end
