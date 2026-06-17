module ZaloPersonal
  module ApiHelper
    def self.request_headers
      api_key = GlobalConfigService.load('ZALO_API_KEY', '')
      {
        'Content-Type' => 'application/json',
        'X-API-Key' => api_key
      }.compact
    end
  end
end
