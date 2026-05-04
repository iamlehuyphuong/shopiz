# Service to sync a ConversationOrder's status from its external sales platform.
# Supports all platforms including tiktok_shop (sync-only).
class ConversationOrders::SyncService
  PROXY_MAP = {
    'kiotviet' => 'ConversationOrders::KiotvietProxy',
    'sapo' => 'ConversationOrders::SapoProxy',
    'haravan' => 'ConversationOrders::HaravanProxy',
    'woocommerce' => 'ConversationOrders::WoocommerceProxy',
    'shopify' => 'ConversationOrders::ShopifyProxy',
    'nhanhvn' => 'ConversationOrders::NhanhvnProxy',
    'tiktok_shop' => 'ConversationOrders::TiktokShopProxy'
  }.freeze

  def initialize(order:)
    @order = order
  end

  def perform
    return { success: false, error: 'Order not pushed yet' } if @order.external_order_id.blank?
    return { success: false, error: 'Platform not specified' } if @order.external_source.blank?

    proxy_class = PROXY_MAP[@order.external_source]
    return { success: false, error: "Unsupported platform: #{@order.external_source}" } if proxy_class.nil?

    sync_order(proxy_class.constantize)
  end

  private

  def sync_order(proxy_class)
    client = proxy_class.new(@order.account)
    result = client.fetch_order(@order.external_order_id)

    return { success: false, error: "Failed to fetch order from #{client.platform_name}" } if result.blank?

    update_order_from_result(client, result)
    { success: true, order: @order }
  rescue StandardError => e
    Rails.logger.error("SyncService error for order #{@order.id}: #{e.message}")
    { success: false, error: "Sync failed: #{e.message}" }
  end

  def update_order_from_result(client, result)
    attrs = {}

    # Map status
    raw_status = extract_raw_status(result)
    mapped = client.map_status(raw_status)
    attrs[:status] = mapped if mapped.present?

    # Update total if available
    total = extract_total(result)
    attrs[:total_amount] = total if total.present?

    @order.update!(attrs) if attrs.present?
  end

  def extract_raw_status(result)
    # Each platform stores status differently
    result['status'] || result['financial_status'] || result['statusCode']
  end

  def extract_total(result)
    result['totalPayment'] || result['total_price'] || result['total'] ||
      result.dig('payment', 'total_amount')
  end
end
