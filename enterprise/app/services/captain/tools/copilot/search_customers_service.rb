class Captain::Tools::Copilot::SearchCustomersService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    'search_customers'
  end

  description 'Search for customers by name or phone'
  param :query, type: :string, desc: 'Name, email or phone number to search for', required: true

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Copilot::Kiotviet::SearchCustomersService',
      'sapo' => 'Captain::Tools::Copilot::Sapo::SearchCustomersService',
      'haravan' => 'Captain::Tools::Copilot::Haravan::SearchCustomersService',
      'shopify' => 'Captain::Tools::Copilot::Shopify::SearchCustomersService',
      'woocommerce' => 'Captain::Tools::Copilot::Woocommerce::SearchCustomersService',
      'nhanhvn' => 'Captain::Tools::Copilot::Nhanhvn::SearchCustomersService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShop::SearchCustomersService'
    }.freeze
  end
end
