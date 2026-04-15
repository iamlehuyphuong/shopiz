class Captain::Tools::SapoGetProductTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::SapoClient
  description 'Search for products on the Sapo store. Returns product name, price, variants, and availability.'
  param :query, type: 'string', desc: 'Product name or keyword to search for'


  def perform(tool_context, **args)
    arguments = args.stringify_keys
    return 'Sapo integration is not active.' unless sapo_active?

    products = fetch_products(arguments['query'])
    return 'No products found.' if products.blank?

    format_products(products)
  end

  private

  def fetch_products(query)
    params = { limit: 10 }
    params[:title] = query if query.present?
    result = sapo_get('products.json', params)
    result&.dig('products') || []
  end

  def format_products(products)
    products.map do |p|
      variants = p['variants']&.map do |v|
        "#{v['title']}: #{format_sapo_currency(v['price'])} (SKU: #{v['sku'] || 'N/A'})"
      end
      "**#{p['name']}** (ID: #{p['id']})\n  Variants: #{variants&.join(', ') || 'N/A'}"
    end.join("\n\n")
  end
end
