class Captain::Tools::Copilot::CreateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    "create_customer"
  end

  description "Create a new customer profile"
  param :name, type: :string, desc: "Customer full name", required: true
  param :phone, type: :string, desc: "Customer phone number", required: false
  param :email, type: :string, desc: "Customer email", required: false
  param :address, type: :string, desc: "Customer address", required: false

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      "kiotviet"     => "Captain::Tools::Copilot::KiotvietCreateCustomerService",
      "sapo"         => "Captain::Tools::Copilot::SapoCreateCustomerService",
      "haravan"      => "Captain::Tools::Copilot::HaravanCreateCustomerService",
      "shopify"      => "Captain::Tools::Copilot::ShopifyCreateCustomerService",
      "woocommerce"  => "Captain::Tools::Copilot::WoocommerceCreateCustomerService",
      "nhanhvn"      => "Captain::Tools::Copilot::NhanhvnCreateCustomerService",
      "tiktok_shop"  => "Captain::Tools::Copilot::TiktokShopCreateCustomerService"
    }.freeze
  end
end
