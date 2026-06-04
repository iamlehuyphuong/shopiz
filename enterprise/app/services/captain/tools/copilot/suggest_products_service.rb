class Captain::Tools::Copilot::SuggestProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::EcomRoutable

  def self.name
    "suggest_products"
  end

  description "Suggest products based on a query or context"
  param :query, type: :string, desc: "Product name keyword or context to search for", required: false

  def execute(**args)
    delegate_to_ecom_tool(**args)
  end

  def active?
    @user.present?
  end

  private

  def ecom_platform_tools
    {
      "kiotviet"     => "Captain::Tools::Copilot::KiotvietSuggestProductsService",
      "sapo"         => "Captain::Tools::Copilot::SapoSuggestProductsService",
      "haravan"      => "Captain::Tools::Copilot::HaravanSuggestProductsService",
      "shopify"      => "Captain::Tools::Copilot::ShopifySuggestProductsService",
      "woocommerce"  => "Captain::Tools::Copilot::WoocommerceSuggestProductsService",
      "nhanhvn"      => "Captain::Tools::Copilot::NhanhvnSuggestProductsService",
      "tiktok_shop"  => "Captain::Tools::Copilot::TiktokShopSuggestProductsService"
    }.freeze
  end
end
