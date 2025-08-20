class Tiktok::SignatureService
  APP_SECRET = ENV["TIKTOK_APP_SECRET"]
  EXCLUDE_KEYS = ["access_token", "sign"]

  class << self
    def signed_url(base_url, params: {}, body: nil, content_type: nil)
      url = "#{base_url}?#{URI.encode_www_form(params)}"
      sign = generate_sign(url, body: body, content_type: content_type)

      "#{url}&sign=#{sign}"
    end

    def generate_sign(url, body: nil, content_type: nil)
      uri = URI.parse(url)

      params = CGI.parse(uri.query.to_s).transform_values(&:first)
      qs = params.except(*EXCLUDE_KEYS).sort.to_h
      param_string = qs.map{|k, v| "#{k}#{v}"}.join
      sign_string = "#{uri.path}#{param_string}"

      if content_type != "multipart/form-data" && body.present?
        sign_string += body
      end
      wrapped_string = "#{APP_SECRET}#{sign_string}#{APP_SECRET}"

      OpenSSL::HMAC.hexdigest("SHA256", APP_SECRET, wrapped_string)
    end
  end
end
