class Captain::Tools::Copilot::GetOrderDetailService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    'get_order_detail'
  end

  description 'Get full details of a specific order'
  param :order_id, type: :string, desc: 'Order ID or code', required: true

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Copilot::Kiotviet::GetOrderDetailService',
      'sapo' => 'Captain::Tools::Copilot::Sapo::GetOrderDetailService',
      'haravan' => 'Captain::Tools::Copilot::Haravan::GetOrderDetailService',
      'shopify' => 'Captain::Tools::Copilot::Shopify::GetOrderDetailService',
      'woocommerce' => 'Captain::Tools::Copilot::Woocommerce::GetOrderDetailService',
      'nhanhvn' => 'Captain::Tools::Copilot::Nhanhvn::GetOrderDetailService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShop::GetOrderDetailService'
    }.freeze
  end
end
