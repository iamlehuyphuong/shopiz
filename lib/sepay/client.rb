require 'net/http'
require 'json'
require 'base64'

class Sepay::Client
  attr_reader :merchant_id, :secret_key, :base_url

  class PaymentError < StandardError; end

  PRODUCTION_URL = 'https://pgapi.sepay.vn'.freeze
  SANDBOX_URL = 'https://pgapi-sandbox.sepay.vn'.freeze

  def initialize(
    merchant_id: GlobalConfig.get_value('SEPAY_COMPANY_CODE').presence || ENV.fetch('SEPAY_COMPANY_CODE', nil),
    secret_key: GlobalConfig.get_value('SEPAY_SECRET_KEY').presence || ENV.fetch('SEPAY_SECRET_KEY', nil),
    sandbox: ENV.fetch('SEPAY_ENV', 'production') == 'sandbox'
  )
    @merchant_id = merchant_id
    @secret_key = secret_key
    @base_url = sandbox ? SANDBOX_URL : PRODUCTION_URL
  end

  # Build the checkout URL that the user should be redirected to
  # Returns a hash with :checkout_url and :form_params for POST redirect
  def create_checkout(amount:, order_id:, description:, return_url:, cancel_url: nil, error_url: nil)
    payload = {
      'merchant' => merchant_id,
      'order_amount' => amount.to_s,
      'order_description' => description,
      'order_invoice_number' => order_id.to_s,
      'currency' => 'VND',
      'operation' => 'PURCHASE',
      'success_url' => return_url,
      'error_url' => error_url || return_url,
      'cancel_url' => cancel_url || return_url
    }

    payload['signature'] = Sepay::Signature.generate(payload, secret_key)

    {
      checkout_url: "#{base_url}/checkout/init",
      form_params: payload
    }
  end

  def verify_webhook_key?(provided_key)
    Sepay::Signature.verify_webhook(provided_key, secret_key)
  end

  private

  def auth_header
    encoded = Base64.strict_encode64("#{merchant_id}:#{secret_key}")
    "Basic #{encoded}"
  end
end
