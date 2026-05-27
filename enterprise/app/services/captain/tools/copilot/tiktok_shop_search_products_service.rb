class Captain::Tools::Copilot::TiktokShopSearchProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TiktokShopClient

  def self.name
    'tiktok_shop_search_products'
  end

  description 'Search for products on the TikTok Shop store by title or keyword.'
  param :query, type: :string, desc: 'Product title or keyword to search'

  def execute(**args)
    arguments = args.stringify_keys
    return 'TikTok Shop integration is not connected.' unless tiktok_shop_active?

    products = fetch_products(arguments['query'])
    return 'No products found.' if products.blank?

    format_products(products)
  end

  def active?
    @user.present? && tiktok_shop_active?
  end

  private

  def fetch_products(query)
    body = { page_size: 10 }
    body[:title] = query if query.present?

    result = tiktok_shop_post('/product/202309/products/search', body)
    result&.dig('data', 'products') || []
  end

  def format_products(products)
    products.map do |p|
      variants_info = p['skus']&.map do |v|
        price = v.dig('price', 'sale_price').to_f
        currency = v.dig('price', 'currency') || 'VND'
        stock = v.dig('inventory', 'quantity').to_i

        sku_details = [format_tiktok_currency(price, currency).to_s, "Stock: #{stock}"]
        sku_details << "SKU: #{v['seller_sku']}" if v['seller_sku'].present?

        " - #{v['id']}: #{sku_details.join(' | ')}"
      end
      "**#{p['title']}** (ID: #{p['id']})\n#{variants_info&.join("\n") || '  No SKUs available'}"
    end.join("\n\n")
  end
end
