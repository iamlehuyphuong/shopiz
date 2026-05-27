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
      'kiotviet' => 'Captain::Tools::Copilot::KiotvietGetOrderDetailService',
      'sapo' => 'Captain::Tools::Copilot::SapoGetOrderDetailService',
      'haravan' => 'Captain::Tools::Copilot::HaravanGetOrderDetailService',
      'shopify' => 'Captain::Tools::Copilot::ShopifyGetOrderDetailService',
      'woocommerce' => 'Captain::Tools::Copilot::WoocommerceGetOrderDetailService',
      'nhanhvn' => 'Captain::Tools::Copilot::NhanhvnGetOrderDetailService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShopGetOrderDetailService'
    }.freeze
  end
end
