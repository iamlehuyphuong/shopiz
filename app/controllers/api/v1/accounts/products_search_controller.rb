class Api::V1::Accounts::ProductsSearchController < Api::V1::Accounts::BaseController
  def index
    query = params[:q].to_s.strip
    conversation_id = params[:conversation_id]
    sources = []

    active_platform = Current.account.active_ecommerce_platform || 'shopiz'

    # Search native Shopiz products
    sources.concat(search_shopiz_products(query))

    # Use account-level active ecommerce platform
    if conversation_id.present? && active_platform != 'shopiz'
      hook = Current.account.hooks.find_by(app_id: active_platform)
      sources.concat(fetch_products_from_integration(hook, query)) if hook
    else
      # Aggregate products from all connected integrations (Fallback)
      integration_hooks.each do |hook|
        products = fetch_products_from_integration(hook, query)
        sources.concat(products)
      end
    end

    # Search Help Center articles as products
    sources.concat(search_help_center_products(query)) if query.present?

    # Prioritize active platform
    sources.sort_by! { |p| p[:source] == active_platform ? 0 : 1 }

    render json: { products: sources }
  end

  private

  def integration_hooks
    Current.account.hooks.where(app_id: %w[shopify kiotviet haravan sapo woocommerce nhanhvn tiktok_shop])
  end

  def fetch_products_from_integration(hook, query)
    case hook.app_id
    when 'shopify'   then fetch_shopify_products(hook, query)
    when 'kiotviet'  then fetch_kiotviet_products(hook, query)
    when 'haravan'   then fetch_haravan_products(hook, query)
    when 'sapo'      then fetch_sapo_products(hook, query)
    when 'woocommerce' then fetch_woocommerce_products(hook, query)
    when 'nhanhvn'   then fetch_nhanhvn_products(hook, query)
    when 'tiktok_shop' then fetch_tiktok_shop_products(hook, query)
    else []
    end
  rescue StandardError => e
    Rails.logger.error("Product search error for #{hook.app_id}: #{e.message}")
    []
  end

  def search_shopiz_products(query)
    escaped_query = ActiveRecord::Base.sanitize_sql_like(query)
    products = Current.account.products.where("meta->>'source' IS NULL OR meta->>'source' = 'shopiz'").includes(:product_variants)
    products = products.where('name ILIKE ? OR description ILIKE ?', "%#{escaped_query}%", "%#{escaped_query}%") if query.present?
    
    results = []
    products.limit(20).each do |product|
      thumbnail = product.meta&.dig('image') || product.meta&.dig('images')&.first
      if product.product_variants.any?
        product.product_variants.each do |variant|
          results << {
            id: product.id.to_s,
            variant_id: variant.id.to_s,
            name: "#{product.name} - #{variant.name}",
            price: variant.price.to_f,
            thumbnail: thumbnail,
            source: 'shopiz',
            metadata: { has_variants: true, sku: variant.sku }
          }
        end
      else
        results << {
          id: product.id.to_s,
          name: product.name,
          price: product.price.to_f,
          thumbnail: thumbnail,
          source: 'shopiz',
          metadata: { has_variants: false, sku: product.sku }
        }
      end
    end
    results
  end

  # --- Shopify ---
  def fetch_shopify_products(hook, query)
    session = ShopifyAPI::Auth::Session.new(shop: hook.reference_id, access_token: hook.access_token)
    client = ShopifyAPI::Clients::Rest::Admin.new(session: session)
    params = { limit: 20 }
    params[:title] = query if query.present?
    products = client.get(path: 'products.json', query: params).body['products'] || []

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

  # --- KiotViet ---
  def fetch_kiotviet_products(hook, query)
    ensure_kiotviet_token(hook)
    params = { pageSize: 20, isActive: true }
    params[:name] = query if query.present?
    response = Faraday.get('https://public.kiotapi.com/products') do |req|
      req.headers['Retailer'] = hook.settings['retailer']
      req.headers['Authorization'] = "Bearer #{hook.access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.params = params
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

  # --- Haravan ---
  def fetch_haravan_products(hook, query)
    params = { limit: 20 }
    params[:title] = query if query.present?
    response = Faraday.get('https://apis.haravan.com/com/products.json') do |req|
      req.headers['Authorization'] = "Bearer #{hook.access_token}"
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    data = JSON.parse(response.body)
    (data['products'] || []).map do |p|
      {
        id: p['id'].to_s,
        name: p['title'],
        price: p['variants']&.first&.dig('price').to_f,
        thumbnail: p.dig('image', 'src'),
        source: 'haravan',
        metadata: { variants_count: p['variants']&.size }
      }
    end
  rescue StandardError => e
    Rails.logger.error("Haravan products error: #{e.message}")
    []
  end

  # --- Sapo ---
  def fetch_sapo_products(hook, query)
    store_name = hook.settings&.dig('store_name') || hook.reference_id
    params = { limit: 20 }
    params[:title] = query if query.present?
    response = Faraday.get("https://#{store_name}.mysapo.net/admin/products.json") do |req|
      req.headers['X-Sapo-Access-Token'] = hook.access_token
      req.headers['Content-Type'] = 'application/json'
      req.params = params
    end
    data = JSON.parse(response.body)
    (data['products'] || []).map do |p|
      {
        id: p['id'].to_s,
        name: p['name'] || p['title'],
        price: p['variants']&.first&.dig('price').to_f,
        thumbnail: p.dig('image', 'src') || p.dig('images', 0, 'src'),
        source: 'sapo',
        metadata: { variants_count: p['variants']&.size }
      }
    end
  rescue StandardError => e
    Rails.logger.error("Sapo products error: #{e.message}")
    []
  end

  # --- WooCommerce ---
  def fetch_woocommerce_products(hook, query)
    store_url = hook.reference_id
    consumer_key = hook.merged_settings['consumer_key']
    consumer_secret = hook.merged_settings['consumer_secret']
    conn = Faraday.new(url: "https://#{store_url}/wp-json/wc/v3") do |f|
      f.request :authorization, :basic, consumer_key, consumer_secret
      f.adapter Faraday.default_adapter
    end
    params = { per_page: 20, status: 'publish' }
    params[:search] = query if query.present?
    response = conn.get('products', params)
    products = JSON.parse(response.body)
    (products.is_a?(Array) ? products : []).map do |p|
      {
        id: p['id'].to_s,
        name: p['name'],
        price: p['price'].to_f,
        thumbnail: p.dig('images', 0, 'src'),
        source: 'woocommerce',
        metadata: { sku: p['sku'] }
      }
    end
  rescue StandardError => e
    Rails.logger.error("WooCommerce products error: #{e.message}")
    []
  end

  # --- Nhanh.vn ---
  def fetch_nhanhvn_products(hook, query)
    params = { version: '2.0', appId: hook.settings['app_id'], businessId: hook.settings['business_id'],
               accessToken: hook.access_token, data: { page: 1 }.to_json }
    params[:data] = { page: 1, name: query }.to_json if query.present?
    response = Faraday.post('https://open.nhanh.vn/api/product/search') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(params)
    end
    parsed = JSON.parse(response.body)
    return [] unless parsed['code'] == 1

    products = parsed.dig('data', 'products') || {}
    products.values.first(20).map do |p|
      {
        id: p['idNhanh'].to_s,
        name: p['name'],
        price: p['price'].to_f,
        thumbnail: p['image'],
        source: 'nhanhvn',
        metadata: { code: p['code'] }
      }
    end
  rescue StandardError => e
    Rails.logger.error("Nhanh.vn products error: #{e.message}")
    []
  end

  # --- TikTok Shop ---
  def fetch_tiktok_shop_products(hook, query)
    return [] if hook.access_token.blank? || hook.settings&.dig('shop_cipher').blank?

    app_key = GlobalConfigService.load('TIKTOK_SHOP_APP_KEY', '')
    return [] if app_key.blank?

    products = tiktok_shop_search(hook, app_key, query)
    products.map { |p| map_tiktok_product(p) }
  rescue StandardError => e
    Rails.logger.error("TikTok Shop products error: #{e.message}")
    []
  end

  def tiktok_shop_search(hook, app_key, query)
    tts_params = { app_key: app_key, shop_cipher: hook.settings['shop_cipher'], timestamp: Time.now.to_i, page_size: 20 }
    body = query.present? ? { search_keyword: query } : {}
    url = 'https://open-api.tiktokglobalshop.com/product/202309/products/search'
    signed_url = ::TiktokShop::SignatureService.signed_url(url, params: tts_params, body: body.to_json, content_type: 'application/json')
    headers = { 'Content-Type' => 'application/json', 'x-tts-access-token' => hook.access_token }
    response = HTTParty.post(signed_url, headers: headers, body: body.to_json)
    JSON.parse(response.body).dig('data', 'products') || []
  end

  def map_tiktok_product(product)
    {
      id: product['id'].to_s, name: product['title'],
      price: product.dig('skus', 0, 'price', 'sale_price').to_f / 100.0,
      thumbnail: product.dig('main_images', 0, 'url_list', 0),
      source: 'tiktok_shop', metadata: { status: product['status'] }
    }
  end

  # --- KiotViet Token Refresh ---
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

  # --- Help Center ---
  def search_help_center_products(query)
    escaped_query = ActiveRecord::Base.sanitize_sql_like(query)
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
