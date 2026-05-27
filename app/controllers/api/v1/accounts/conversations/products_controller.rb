class Api::V1::Accounts::Conversations::ProductsController < Api::V1::Accounts::Conversations::BaseController
  def index
    platform = params[:source] || @conversation.inbox.sales_config&.dig('platform') || 'shopiz'

    if platform == 'shopiz'
      products = fetch_shopiz_products(params[:q].to_s.strip, params[:page].to_i)
      return render json: { products: products }
    end

    hook = Current.account.hooks.find_by(app_id: platform)
    return render json: { products: [] }, status: :ok unless hook

    products = fetch_products(hook, params[:q].to_s.strip, params[:page].to_i)
    render json: { products: products }
  end

  private

  def fetch_products(hook, query, page)
    case hook.app_id
    when 'kiotviet'  then fetch_kiotviet_products(hook, query, page)
    when 'sapo'      then fetch_sapo_products(hook, query, page)
    when 'haravan'   then fetch_haravan_products(hook, query, page)
    when 'shopify'   then fetch_shopify_products(hook, query, page)
    when 'woocommerce' then fetch_woocommerce_products(hook, query, page)
    when 'nhanhvn'   then fetch_nhanhvn_products(hook, query, page)
    when 'tiktok_shop' then fetch_tiktok_shop_products(hook, query, page)
    else []
    end
  rescue StandardError => e
    Rails.logger.error("Product fetch error for #{hook.app_id}: #{e.message}")
    []
  end

  # ===== Flowify (Native) =====

  def fetch_shopiz_products(query, page)
    products = Current.account.products.active.order(created_at: :desc)

    if query.present?
      search_term = "%#{query}%"
      products = products.where('name ILIKE ? OR sku ILIKE ?', search_term, search_term)
    end

    products = products.page(page + 1).per(20)

    products.map do |p|
      thumbnail = nil
      if p.respond_to?(:images) && p.images.is_a?(Array)
        thumbnail = p.images.first
      elsif p.meta.is_a?(Hash) && p.meta['images'].is_a?(Array)
        thumbnail = p.meta['images'].first
      end

      {
        id: p.id.to_s,
        name: p.name,
        price: p.price.to_f,
        thumbnail: thumbnail,
        source: 'shopiz',
        in_stock: true
      }
    end
  end

  # ===== KiotViet =====

  def fetch_kiotviet_products(hook, query, page)
    ensure_kiotviet_token(hook)
    params = { pageSize: 20, currentItem: page * 20, isActive: true }
    params[:name] = query if query.present?

    response = Faraday.get('https://public.kiotapi.com/products') do |req|
      req.headers['Retailer'] = hook.settings['retailer']
      req.headers['Authorization'] = "Bearer #{hook.access_token}"
      req.params = params
    end
    data = JSON.parse(response.body)
    (data['data'] || []).map do |p|
      { id: p['id'].to_s, name: p['name'], price: p['basePrice'].to_f,
        thumbnail: p.dig('images', 0), source: 'kiotviet',
        in_stock: (p['inventories']&.sum { |i| i['onHand'].to_i } || 0).positive?,
        metadata: { code: p['code'] } }
    end
  end

  # ===== Sapo =====

  def fetch_sapo_products(hook, query, page)
    store_name = hook.settings&.dig('store_name') || hook.reference_id
    params = { limit: 20, page: [page + 1, 1].max }
    params[:title] = query if query.present?

    response = Faraday.get("https://#{store_name}.mysapo.net/admin/products.json") do |req|
      req.headers['X-Sapo-Access-Token'] = hook.access_token
      req.params = params
    end
    data = JSON.parse(response.body)
    (data['products'] || []).map do |p|
      { id: p['id'].to_s, name: p['name'] || p['title'],
        price: p['variants']&.first&.dig('price').to_f,
        thumbnail: p.dig('image', 'src') || p.dig('images', 0, 'src'),
        source: 'sapo', in_stock: true }
    end
  end

  # ===== Haravan =====

  def fetch_haravan_products(hook, query, page)
    params = { limit: 20, page: [page + 1, 1].max }
    params[:title] = query if query.present?

    response = Faraday.get('https://apis.haravan.com/com/products.json') do |req|
      req.headers['Authorization'] = "Bearer #{hook.access_token}"
      req.params = params
    end
    data = JSON.parse(response.body)
    (data['products'] || []).map do |p|
      { id: p['id'].to_s, name: p['title'],
        price: p['variants']&.first&.dig('price').to_f,
        thumbnail: p.dig('image', 'src'), source: 'haravan', in_stock: true }
    end
  end

  # ===== Shopify =====

  def fetch_shopify_products(hook, query, _page)
    session = ShopifyAPI::Auth::Session.new(shop: hook.reference_id, access_token: hook.access_token)
    client = ShopifyAPI::Clients::Rest::Admin.new(session: session)
    params = { limit: 20 }
    params[:title] = query if query.present?
    products = client.get(path: 'products.json', query: params).body['products'] || []

    products.map do |p|
      { id: p['id'].to_s, name: p['title'],
        price: p['variants']&.first&.dig('price').to_f,
        thumbnail: p.dig('image', 'src'), source: 'shopify', in_stock: true }
    end
  end

  # ===== WooCommerce =====

  def fetch_woocommerce_products(hook, query, page)
    conn = woo_connection(hook)
    params = { per_page: 20, page: [page + 1, 1].max, status: 'publish' }
    params[:search] = query if query.present?

    response = conn.get('products', params)
    data = JSON.parse(response.body)
    (data.is_a?(Array) ? data : []).map do |p|
      { id: p['id'].to_s, name: p['name'], price: p['price'].to_f,
        thumbnail: p.dig('images', 0, 'src'), source: 'woocommerce',
        in_stock: p['stock_status'] == 'instock' }
    end
  end

  def woo_connection(hook)
    Faraday.new(url: "https://#{hook.reference_id}/wp-json/wc/v3") do |f|
      f.request :authorization, :basic, hook.settings['consumer_key'], hook.settings['consumer_secret']
      f.adapter Faraday.default_adapter
    end
  end

  # ===== Nhanh.vn =====

  def fetch_nhanhvn_products(hook, query, page)
    data_payload = { page: [page + 1, 1].max }
    data_payload[:name] = query if query.present?

    params = { version: '2.0', appId: hook.settings['app_id'],
               businessId: hook.settings['business_id'], accessToken: hook.access_token,
               data: data_payload.to_json }
    response = Faraday.post('https://open.nhanh.vn/api/product/search') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(params)
    end
    parsed = JSON.parse(response.body)
    return [] unless parsed['code'] == 1

    products = parsed.dig('data', 'products') || {}
    products.values.first(20).map do |p|
      { id: p['idNhanh'].to_s, name: p['name'], price: p['price'].to_f,
        thumbnail: p['image'], source: 'nhanhvn', in_stock: p.dig('inventory', 'remain').to_i.positive? }
    end
  end

  # ===== TikTok Shop =====

  def fetch_tiktok_shop_products(hook, query, _page)
    app_key = GlobalConfigService.load('TIKTOK_SHOP_APP_KEY', '')
    return [] if app_key.blank?

    tts_params = { app_key: app_key, shop_cipher: hook.settings['shop_cipher'],
                   timestamp: Time.now.to_i, page_size: 20 }
    body = query.present? ? { search_keyword: query } : {}
    url = 'https://open-api.tiktokglobalshop.com/product/202309/products/search'
    signed_url = ::TiktokShop::SignatureService.signed_url(url, params: tts_params, body: body.to_json, content_type: 'application/json')
    headers = { 'Content-Type' => 'application/json', 'x-tts-access-token' => hook.access_token }
    response = HTTParty.post(signed_url, headers: headers, body: body.to_json)
    products = JSON.parse(response.body).dig('data', 'products') || []

    products.map do |p|
      { id: p['id'].to_s, name: p['title'],
        price: p.dig('skus', 0, 'price', 'sale_price').to_f / 100.0,
        thumbnail: p.dig('main_images', 0, 'url_list', 0),
        source: 'tiktok_shop', in_stock: p['status']&.to_i == 4 }
    end
  end

  # ===== Shared Helpers =====

  def ensure_kiotviet_token(hook)
    expires_at = hook.settings&.dig('token_expires_at')
    return if expires_at.present? && Time.zone.parse(expires_at) > Time.current

    token_data = Faraday.post('https://id.kiotviet.vn/connect/token') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        scopes: 'PublicApi.Access', grant_type: 'client_credentials',
        client_id: hook.settings['client_id'], client_secret: hook.settings['client_secret']
      )
    end
    parsed = JSON.parse(token_data.body)
    return if parsed['access_token'].blank?

    hook.update!(
      access_token: parsed['access_token'],
      settings: hook.settings.merge('token_expires_at' => (Time.current + parsed['expires_in'].to_i.seconds).iso8601)
    )
  end
end
