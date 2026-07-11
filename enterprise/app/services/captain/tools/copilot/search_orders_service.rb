class Captain::Tools::Copilot::SearchOrdersService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    'search_orders'
  end

  description 'Search orders by order ID or phone number'
  param :order_id, type: :string, desc: 'Order ID or code', required: false
  param :phone_number, type: :string, desc: 'Customer phone number', required: false

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Copilot::KiotvietSearchOrdersService',
      'sapo' => 'Captain::Tools::Copilot::SapoSearchOrdersService',
      'haravan' => 'Captain::Tools::Copilot::HaravanSearchOrdersService',
      'shopify' => 'Captain::Tools::Copilot::ShopifySearchOrdersService',
      'woocommerce' => 'Captain::Tools::Copilot::WoocommerceSearchOrdersService',
      'nhanhvn' => 'Captain::Tools::Copilot::NhanhvnSearchOrdersService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShopSearchOrdersService'
    }.freeze
  end
end
