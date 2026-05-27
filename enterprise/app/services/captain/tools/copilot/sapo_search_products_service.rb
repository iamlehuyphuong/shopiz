class Captain::Tools::Copilot::SapoSearchProductsService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::SapoClient
  def self.name
    'sapo_search_products'
  end

  description 'Search for products on the Sapo store by name or keyword.'
  param :query, type: :string, desc: 'Product name or keyword to search'

  def execute(**args)
    arguments = args.stringify_keys
    return 'Sapo integration is not connected.' unless sapo_active?

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
      variants_info = p['variants']&.map do |v|
        " - #{v['title']}: #{format_sapo_currency(v['price'])} (SKU: #{v['sku'] || 'N/A'})"
      end
      "**#{p['name']}** (ID: #{p['id']})\n#{variants_info&.join("\n") || '  No variants'}"
    end.join("\n\n")
  end
end
