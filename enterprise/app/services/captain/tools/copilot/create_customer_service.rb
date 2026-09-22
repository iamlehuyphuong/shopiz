class Captain::Tools::Copilot::CreateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    'create_customer'
  end

  description 'Create a new customer profile'
  param :name, type: :string, desc: 'Customer full name', required: true
  param :phone, type: :string, desc: 'Customer phone number', required: false
  param :email, type: :string, desc: 'Customer email', required: false
  param :address, type: :string, desc: 'Customer address', required: false

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Copilot::Kiotviet::CreateCustomerService',
      'sapo' => 'Captain::Tools::Copilot::Sapo::CreateCustomerService',
      'haravan' => 'Captain::Tools::Copilot::Haravan::CreateCustomerService',
      'shopify' => 'Captain::Tools::Copilot::Shopify::CreateCustomerService',
      'woocommerce' => 'Captain::Tools::Copilot::Woocommerce::CreateCustomerService',
      'nhanhvn' => 'Captain::Tools::Copilot::Nhanhvn::CreateCustomerService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShop::CreateCustomerService'
    }.freeze
  end
end
