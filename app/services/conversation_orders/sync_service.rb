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

  def initialize(order:, user: nil)
    @order = order
    @user = user
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
    @order.update_column(:last_synced_at, Time.current)
    log_activity(:synced)
    { success: true, order: @order }
  rescue StandardError => e
    Rails.logger.error("SyncService error for order #{@order.id}: #{e.message}")
    { success: false, error: "Sync failed: #{e.message}" }
  end

  def update_order_from_result(client, result)
    attrs = {}

    # Map status — delegate extraction to platform-specific proxy
    raw_status = client.extract_raw_status(result)
    mapped = client.map_status(raw_status)
    attrs[:status] = mapped if mapped.present?

    @order.update!(attrs) if attrs.present?

    # Update total if available — delegate extraction to proxy
    total = client.extract_total(result)
    @order.update_column(:total_amount, total) if total.present? # bypass before_save calculate_total_amount
  end

  def log_activity(action_type)
    ConversationOrders::OrderActivityMessageService.new(
      conversation: @order.conversation,
      order: @order,
      action_type: action_type,
      user: @user
    ).perform
  end
end
