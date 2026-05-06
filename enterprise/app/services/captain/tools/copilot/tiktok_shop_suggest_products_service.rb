class Captain::Tools::Copilot::TiktokShopSuggestProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TiktokShopClient

  def self.name
    'tiktok_shop_suggest_products'
  end

  description 'Suggest products to buyers from TikTok Shop based on chat context. ' \
              'Useful for answering "Do you have X?" or recommending items.'
  param :context, type: :string, desc: 'What the customer is looking for (e.g., "red t-shirt")'

  def execute(**args)
    arguments = args.stringify_keys
    return 'TikTok Shop integration is not connected.' unless tiktok_shop_active?

    query = arguments['context'].to_s.strip
    return 'Please provide a context or keyword to suggest products.' if query.blank?

    products = fetch_products(query)
    return "No products found matching: #{query}" if products.blank?

    format_suggestions(products)
  end

  def active?
    @user.present? && tiktok_shop_active?
  end

  private

  def fetch_products(query)
    body = { page_size: 5, title: query }
    result = tiktok_shop_post('/product/202309/products/search', body)
    result&.dig('data', 'products') || []
  end

  def format_suggestions(products)
    lines = ["🛍️ **Suggested Products from TikTok Shop**\n"]

    products.each do |p|
      price = p['skus']&.first&.dig('price', 'sale_price').to_f
      currency = p['skus']&.first&.dig('price', 'currency') || 'VND'
      stock = p['skus']&.sum { |v| v.dig('inventory', 'quantity').to_i } || 0

      lines << "- **#{p['title']}**"
      lines << "  Price: #{format_tiktok_currency(price, currency)}"
      lines << "  Stock: #{stock} available"
      lines << "  Product ID: #{p['id']}"
    end

    lines.join("\n")
  end
end
