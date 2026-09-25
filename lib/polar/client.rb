# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'openssl'

module Polar
  class Client
    API_BASE = 'https://api.polar.sh/v1'

    def initialize
      @api_key = GlobalConfig.get_value('POLAR_API_KEY').presence || ENV.fetch('POLAR_API_KEY', '')
    end

    def create_checkout(amount_cents:, product_id:, success_url:, metadata: {})
      uri = URI("#{API_BASE}/checkouts/")
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'

      request.body = {
        products: [product_id],
        prices: {
          product_id => [
            {
              price_amount: amount_cents,
              price_currency: 'usd',
              type: 'fixed'
            }
          ]
        },
        success_url: success_url,
        metadata: metadata
      }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("[Polar] Failed to create checkout: #{e.message}")
      nil
    end

    def verify_webhook_signature?(payload, headers)
      secret = GlobalConfig.get_value('POLAR_WEBHOOK_SECRET').presence || ENV.fetch('POLAR_WEBHOOK_SECRET', '')
      return false if secret.blank?

      # Parse Standard Webhooks headers
      msg_id = headers['webhook-id']
      msg_signature_header = headers['webhook-signature']
      msg_timestamp = headers['webhook-timestamp']

      return false if msg_id.blank? || msg_signature_header.blank? || msg_timestamp.blank?

      # Construct the signed content per Standard Webhooks protocol
      signed_content = "#{msg_id}.#{msg_timestamp}.#{payload}"

      # Base64 decode the secret to get the raw bytes
      decoded_secret = Base64.strict_decode64(secret.gsub(/^whsec_/, ''))

      # Compute HMAC SHA256
      expected_signature = OpenSSL::HMAC.digest('sha256', decoded_secret, signed_content)
      expected_signature_base64 = Base64.strict_encode64(expected_signature)

      # Extract signatures provided (can be multiple comma-separated)
      provided_signatures = msg_signature_header.split(' ').map { |s| s.split(',').last }

      # Validate
      provided_signatures.any? do |provided_sig|
        ActiveSupport::SecurityUtils.secure_compare(expected_signature_base64, provided_sig)
      end
    rescue StandardError => e
      Rails.logger.error("[Polar] Webhook signature verification failed: #{e.message}")
      false
    end
  end
end
