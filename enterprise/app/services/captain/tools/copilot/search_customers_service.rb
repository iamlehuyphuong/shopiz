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
      'kiotviet' => 'Captain::Tools::Copilot::KiotvietSearchCustomersService',
      'sapo' => 'Captain::Tools::Copilot::SapoSearchCustomersService',
      'haravan' => 'Captain::Tools::Copilot::HaravanSearchCustomersService',
      'shopify' => 'Captain::Tools::Copilot::ShopifySearchCustomersService',
      'woocommerce' => 'Captain::Tools::Copilot::WoocommerceSearchCustomersService',
      'nhanhvn' => 'Captain::Tools::Copilot::NhanhvnSearchCustomersService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShopSearchCustomersService'
    }.freeze
  end
end
