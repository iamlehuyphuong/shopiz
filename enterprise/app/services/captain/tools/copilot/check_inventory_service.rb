class Captain::Tools::Copilot::CheckInventoryService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    'check_inventory'
  end

  description 'Check inventory and stock levels for specific products'
  param :product_ids, type: :string, desc: 'Comma separated list of product IDs', required: true

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Copilot::Kiotviet::CheckInventoryService',
      'sapo' => 'Captain::Tools::Copilot::Sapo::CheckInventoryService',
      'haravan' => 'Captain::Tools::Copilot::Haravan::CheckInventoryService',
      'shopify' => 'Captain::Tools::Copilot::Shopify::CheckInventoryService',
      'woocommerce' => 'Captain::Tools::Copilot::Woocommerce::CheckInventoryService',
      'nhanhvn' => 'Captain::Tools::Copilot::Nhanhvn::CheckInventoryService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShop::CheckInventoryService'
    }.freeze
  end
end
