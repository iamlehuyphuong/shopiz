class Captain::Tools::Copilot::PushOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    'push_order'
  end

  description 'Push a draft order to the e-commerce platform'
  param :conversation_order_id, type: :integer, desc: 'Local Shopiz Order ID', required: true

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Copilot::Kiotviet::PushOrderService',
      'sapo' => 'Captain::Tools::Copilot::Sapo::PushOrderService',
      'haravan' => 'Captain::Tools::Copilot::Haravan::PushOrderService',
      'shopify' => 'Captain::Tools::Copilot::Shopify::PushOrderService',
      'woocommerce' => 'Captain::Tools::Copilot::Woocommerce::PushOrderService',
      'nhanhvn' => 'Captain::Tools::Copilot::Nhanhvn::PushOrderService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShop::PushOrderService'
    }.freeze
  end
end
