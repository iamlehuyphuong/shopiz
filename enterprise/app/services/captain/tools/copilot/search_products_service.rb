class Captain::Tools::Copilot::SearchProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    'search_products'
  end

  description 'Search for products by keyword, or list all products'
  param :query, type: :string, desc: 'Product name keyword to search for', required: false
  param :category_id, type: :integer, desc: 'Filter by category ID', required: false

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Copilot::KiotvietSearchProductsService',
      'sapo' => 'Captain::Tools::Copilot::SapoSearchProductsService',
      'haravan' => 'Captain::Tools::Copilot::HaravanSearchProductsService',
      'shopify' => 'Captain::Tools::Copilot::ShopifySearchProductsService',
      'woocommerce' => 'Captain::Tools::Copilot::WoocommerceSearchProductsService',
      'nhanhvn' => 'Captain::Tools::Copilot::NhanhvnSearchProductsService',
      'tiktok_shop' => 'Captain::Tools::Copilot::TiktokShopSearchProductsService'
    }.freeze
  end
end
