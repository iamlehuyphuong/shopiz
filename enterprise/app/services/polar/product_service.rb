class Polar::ProductService
  CACHE_KEY = 'polar:products:list'.freeze
  CACHE_KEYS_EXPIRY = 2.hours

  class << self
    def find(id)
      return if id.blank?

      ::Polar::Product.get(id).table
    rescue StandardError => e
      log_error('find', e)
      nil
    end

    def by_type(type)
      products = list
      return [] if products.blank?

      products.select do |product|
        product.dig('metadata', 'type') == type
      end
    rescue StandardError => e
      log_error('by_type', e)
      []
    end

    def by_name(name)
      products = list
      return if products.blank?

      products.find { |product| product.dig('metadata', 'sku') == name }
    end

    private

    def list
      result = Redis::Alfred.get(CACHE_KEY)
      return JSON.parse(result).pluck('table') if result

      products = ::Polar::Product.list(limit: 50)
      Redis::Alfred.setex(CACHE_KEY, products.to_json, CACHE_KEYS_EXPIRY)
      products
    rescue StandardError => e
      log_error('list', e)
      []
    end

    def log_error(action, error)
      Rails.logger.error("[Polar::ProductService] #{action} failed: #{error.class} - #{error.message}")
    end
  end
end
