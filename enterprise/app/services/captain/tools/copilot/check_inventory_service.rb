class Captain::Tools::Copilot::CheckInventoryService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    "check_inventory"
  end

  description "Check inventory and stock levels for specific products"
  param :product_ids, type: :string, desc: "Comma separated list of product IDs", required: true

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      "kiotviet"     => "Captain::Tools::Copilot::KiotvietCheckInventoryService",
      "sapo"         => "Captain::Tools::Copilot::SapoCheckInventoryService",
      "haravan"      => "Captain::Tools::Copilot::HaravanCheckInventoryService",
      "shopify"      => "Captain::Tools::Copilot::ShopifyCheckInventoryService",
      "woocommerce"  => "Captain::Tools::Copilot::WoocommerceCheckInventoryService",
      "nhanhvn"      => "Captain::Tools::Copilot::NhanhvnCheckInventoryService",
      "tiktok_shop"  => "Captain::Tools::Copilot::TiktokShopCheckInventoryService"
    }.freeze
  end
end
