class Captain::Tools::Copilot::CreateOrderService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    "create_order"
  end

  description "Create a draft order for the customer"
  param :conversation_id, type: :integer, desc: "Conversation display ID to attach the order to", required: true
  param :product_items, type: :string, desc: "JSON array of items: [{\"id\":\"SP001\",\"qty\":2}]", required: true
  param :customer_name, type: :string, desc: "Customer name", required: false
  param :customer_phone, type: :string, desc: "Customer phone", required: false
  param :delivery_address, type: :string, desc: "Delivery address", required: false
  param :note, type: :string, desc: "Order note", required: false

  def execute(**args)
    unless @conversation&.account&.ai_allow_create_order
      return 'AI order creation is disabled for this account. Enable it in Sales Settings.'
    end

    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      "kiotviet"     => "Captain::Tools::Copilot::KiotvietCreateOrderService",
      "sapo"         => "Captain::Tools::Copilot::SapoCreateOrderService",
      "haravan"      => "Captain::Tools::Copilot::HaravanCreateOrderService",
      "shopify"      => "Captain::Tools::Copilot::ShopifyCreateOrderService",
      "woocommerce"  => "Captain::Tools::Copilot::WoocommerceCreateOrderService",
      "nhanhvn"      => "Captain::Tools::Copilot::NhanhvnCreateOrderService",
      "tiktok_shop"  => "Captain::Tools::Copilot::TiktokShopCreateOrderService"
    }.freeze
  end
end
