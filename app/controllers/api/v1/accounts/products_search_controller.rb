class Api::V1::Accounts::ProductsSearchController < Api::V1::Accounts::BaseController
  def index
    query = params[:q].to_s.strip
    sources = []

    # Aggregate products from all connected integrations
    integration_hooks.each do |hook|
      products = fetch_products_from_integration(hook, query)
      sources.concat(products)
    end

    # Search Help Center articles as products
    sources.concat(search_help_center_products(query)) if query.present?

    render json: { products: sources }
  end

  private

  def integration_hooks
    Current.account.hooks.where(app_id: %w[shopify kiotviet haravan sapo woocommerce nhanhvn])
  end

  def fetch_products_from_integration(hook, query)
    case hook.app_id
    when 'shopify'
      fetch_shopify_products(hook, query)
    when 'kiotviet'
      fetch_kiotviet_products(hook, query)
    else
      []
    end
  rescue StandardError => e
    Rails.logger.error("Product search error for #{hook.app_id}: #{e.message}")
    []
  end

  def fetch_shopify_products(hook, _query)
    session = ShopifyAPI::Auth::Session.new(shop: hook.reference_id, access_token: hook.access_token)
    client = ShopifyAPI::Clients::Rest::Admin.new(session: session)
    products = client.get(path: 'products.json', query: { limit: 20 }).body['products'] || []

    products.map do |p|
      {
        id: p['id'].to_s,
        name: p['title'],
        price: p['variants']&.first&.dig('price').to_f,
        thumbnail: p.dig('image', 'src'),
        source: 'shopify',
        metadata: { variants_count: p['variants']&.size }
      }
    end
  rescue StandardError => e
    Rails.logger.error("Shopify products error: #{e.message}")
    []
  end

  def fetch_kiotviet_products(hook, _query)
    ensure_kiotviet_token(hook)
    response = Faraday.get('https://public.kiotapi.com/products') do |req|
      req.headers['Retailer'] = hook.settings['retailer']
      req.headers['Authorization'] = "Bearer #{hook.access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.params = { pageSize: 20, isActive: true }
    end
    data = JSON.parse(response.body)
    (data['data'] || []).map do |p|
      {
        id: p['id'].to_s,
        name: p['name'],
        price: p['basePrice'].to_f,
        thumbnail: p.dig('images', 0),
        source: 'kiotviet',
        metadata: { code: p['code'] }
      }
    end
  rescue StandardError => e
    Rails.logger.error("KiotViet products error: #{e.message}")
    []
  end

  def ensure_kiotviet_token(hook)
    expires_at = hook.settings&.dig('token_expires_at')
    return if expires_at.present? && Time.zone.parse(expires_at) > Time.current

    token_data = Faraday.post('https://id.kiotviet.vn/connect/token') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        scopes: 'PublicApi.Access',
        grant_type: 'client_credentials',
        client_id: hook.settings['client_id'],
        client_secret: hook.settings['client_secret']
      )
    end
    parsed = JSON.parse(token_data.body)
    return if parsed['access_token'].blank?

    hook.update!(
      access_token: parsed['access_token'],
      settings: hook.settings.merge('token_expires_at' => (Time.current + parsed['expires_in'].to_i.seconds).iso8601)
    )
  end

  def search_help_center_products(query)
    escaped_query = sanitize_sql_like(query)
    articles = Current.account.articles
                      .where('title ILIKE ? OR description ILIKE ?', "%#{escaped_query}%", "%#{escaped_query}%")
                      .limit(10)
    articles.map do |article|
      {
        id: "article_#{article.id}",
        name: article.title,
        price: 0,
        thumbnail: nil,
        source: 'helpcenter',
        metadata: { article_id: article.id, slug: article.slug }
      }
    end
  rescue StandardError => e
    Rails.logger.error("Help Center product search error: #{e.message}")
    []
  end
end
