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
      'kiotviet' => 'Captain::Tools::Copilot::Kiotviet::SearchOrdersService',
      'sapo' => 'Captain::Tools::Copilot::Sapo::SearchOrdersService',
      'haravan' => 'Captain::Tools::Copilot::Haravan::SearchOrdersService',
      'shopify' => 'Captain::Tools::Copilot::Shopify::SearchOrdersService',
      'woocommerce' => 'Captain::Tools::Copilot::Woocommerce::SearchOrdersService',
      'nhanhvn' => 'Captain::Tools::Copilot::Nhanhvn::SearchOrdersService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShop::SearchOrdersService'
    }.freeze
  end
end
