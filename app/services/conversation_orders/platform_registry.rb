# Shared registry of platform proxy classes for order integrations.
# Used by PushService, SyncService, and Sales::ProductsSyncService
# to avoid maintaining duplicate PROXY_MAP hashes.
module ConversationOrders::PlatformRegistry
  # All supported platform proxies (push + sync capable)
  PROXY_MAP = {
    'kiotviet' => 'ConversationOrders::KiotvietProxy',
    'sapo' => 'ConversationOrders::SapoProxy',
    'haravan' => 'ConversationOrders::HaravanProxy',
    'woocommerce' => 'ConversationOrders::WoocommerceProxy',
    'shopify' => 'ConversationOrders::ShopifyProxy',
    'nhanhvn' => 'ConversationOrders::NhanhvnProxy',
    'tiktok_shop' => 'ConversationOrders::TiktokShopProxy'
  }.freeze

  # Platforms where we cannot create orders via API — orders originate from the marketplace
  SYNC_ONLY_PLATFORMS = %w[tiktok_shop].freeze

  def self.proxy_for(platform)
    class_name = PROXY_MAP[platform]
    return nil if class_name.blank?

    class_name.constantize
  end

  def self.pushable?(platform)
    PROXY_MAP.key?(platform) && !SYNC_ONLY_PLATFORMS.include?(platform)
  end
end
