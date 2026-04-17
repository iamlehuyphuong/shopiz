require 'openssl'
require 'base64'

module Sepay
  module Signature
    module_function

    # Fields in the exact order required by SePay for signature generation
    SIGNING_FIELDS = %w[
      order_amount merchant currency operation order_description
      order_invoice_number customer_id payment_method
      success_url error_url cancel_url
    ].freeze

    # Generate HMAC-SHA256 signature for SePay checkout form
    # Format: field1=value1,field2=value2,... (comma-separated, in exact field order)
    # Result: base64(hmac_sha256(string, secret_key))
    def generate(payload, secret_key)
      data = payload.transform_keys(&:to_s)
      parts = SIGNING_FIELDS.filter_map do |field|
        value = data[field]
        "#{field}=#{value}" if value.present?
      end
      sign_string = parts.join(',')
      raw_hmac = OpenSSL::HMAC.digest('SHA256', secret_key.to_s, sign_string)
      Base64.strict_encode64(raw_hmac)
    end

    # Verify webhook X-Secret-Key header
    def verify_webhook(provided_key, expected_key)
      return false if provided_key.blank? || expected_key.blank?

      ActiveSupport::SecurityUtils.secure_compare(provided_key, expected_key)
    end
  end
end
