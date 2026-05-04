class TiktokShop::AuthService
  AUTHORIZED_SHOPS_URL = "https://open-api.tiktokglobalshop.com/authorization/202309/shops"
  GET_ACCESS_TOKEN_URL = "https://auth.tiktok-shops.com/api/v2/token/get"
  APP_KEY = GlobalConfigService.load('TIKTOK_SHOP_APP_KEY', '')
  APP_SECRET = GlobalConfigService.load('TIKTOK_SHOP_APP_SECRET', '')

  def initialize(account_id, code)
    @account_id = account_id
    @code = code
  end

  def perform
    token_data = get_access_token
    access_token = token_data.dig("data", "access_token")
    shop_data = get_shop_info(access_token)

    data = build_data(token_data, shop_data)
    shop_name = data[:shop_name]
    session_id = store_data(data.except!(:shop_name))
    [session_id, shop_name]
  end

  private

  def get_access_token
    params = {
      app_key: APP_KEY,
      app_secret: APP_SECRET,
      auth_code: @code,
      grant_type: "authorized_code",
    }
    url = "#{GET_ACCESS_TOKEN_URL}?#{URI.encode_www_form(params)}"
    response = HTTParty.get(url)

    JSON.parse(response.body)
  end

  def get_shop_info(access_token)
    params = {
      app_key: APP_KEY,
      timestamp: Time.now.to_i,
      access_token: access_token,
    }
    url = ::TiktokShop::SignatureService.signed_url(AUTHORIZED_SHOPS_URL, params: params)

    res = HTTParty.get(url, headers: {"x-tts-access-token" => access_token})
    JSON.parse(res.body)
  end

  def build_data(token_data, shop_data)
    shop = shop_data.dig("data", "shops")&.first

    {
      access_token: token_data.dig("data", "access_token"),
      refresh_token: token_data.dig("data", "refresh_token"),
      expires_in: token_data.dig("data", "access_token_expire_in"),
      shop_id: shop["id"],
      shop_name: shop["name"],
      shop_cipher: shop["cipher"],
    }
  end

  def store_data(data)
    session_id = SecureRandom.uuid
    ttl = 10 * 60
    redis = Redis.new(url: ENV["REDIS_URL"])

    redis.setex("tiktok_session:#{session_id}", ttl, data.to_json)
    session_id
  end
end
