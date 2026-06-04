class Captain::Tools::Copilot::PushOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    "push_order"
  end

  description "Push a draft order to the e-commerce platform"
  param :conversation_order_id, type: :integer, desc: "Local Shopiz Order ID", required: true

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      "kiotviet"     => "Captain::Tools::Copilot::KiotvietPushOrderService",
      "sapo"         => "Captain::Tools::Copilot::SapoPushOrderService",
      "haravan"      => "Captain::Tools::Copilot::HaravanPushOrderService",
      "shopify"      => "Captain::Tools::Copilot::ShopifyPushOrderService",
      "woocommerce"  => "Captain::Tools::Copilot::WoocommercePushOrderService",
      "nhanhvn"      => "Captain::Tools::Copilot::NhanhvnPushOrderService",
      "tiktok_shop"  => "Captain::Tools::Copilot::TiktokShopPushOrderService"
    }.freeze
  end
end
