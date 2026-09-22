class Captain::Tools::Copilot::UpdateCustomerService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    'update_customer'
  end

  description 'Update an existing customer profile'
  param :customer_id, type: :string, desc: 'Customer ID or code', required: true
  param :name, type: :string, desc: 'Customer full name', required: false
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
      'kiotviet' => 'Captain::Tools::Copilot::Kiotviet::UpdateCustomerService',
      'sapo' => 'Captain::Tools::Copilot::Sapo::UpdateCustomerService',
      'haravan' => 'Captain::Tools::Copilot::Haravan::UpdateCustomerService',
      'shopify' => 'Captain::Tools::Copilot::Shopify::UpdateCustomerService',
      'woocommerce' => 'Captain::Tools::Copilot::Woocommerce::UpdateCustomerService',
      'nhanhvn' => 'Captain::Tools::Copilot::Nhanhvn::UpdateCustomerService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShop::UpdateCustomerService'
    }.freeze
  end
end
