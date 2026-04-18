# frozen_string_literal: true

# Central service for resolving which payment gateway to use
# Based on account locale (VN vs international) and configured routing rules
class Enterprise::Billing::PaymentRouter
  METHODS = %w[payos sepay].freeze

  def initialize(account)
    @account = account
    @config = load_config
  end

  # Returns the best payment method for this account
  def resolve
    default_method = vietnam_account? ? @config['vn_default'] : @config['intl_default']
    return default_method if enabled?(default_method)

    fallback_chain.find { |m| enabled?(m) } || METHODS.first
  end

  # Returns ordered list of available methods for this account's region
  def available_methods
    primary = vietnam_account? ? @config['vn_default'] : @config['intl_default']
    fallbacks = vietnam_account? ? @config['vn_fallback'] : @config['intl_fallback']
    ([primary] + (fallbacks || [])).uniq.select { |m| enabled?(m) }
  end

  # Returns the next fallback method after the given method fails
  def next_fallback(failed_method)
    chain = available_methods
    idx = chain.index(failed_method)
    return nil if idx.nil?

    chain[idx + 1]
  end

  # Whether the user should be shown a method picker dialog
  def show_method_dialog?
    !vietnam_account? && available_methods.size > 1
  end

  private

  def enabled?(method)
    (@config['enabled'] || METHODS).include?(method)
  end

  def vietnam_account?
    locale = @account.locale || 'vi'
    locale == 'vi'
  end

  def fallback_chain
    vietnam_account? ? (@config['vn_fallback'] || []) : (@config['intl_fallback'] || [])
  end

  def load_config
    raw = GlobalConfig.get_value('PAYMENT_GATEWAY_CONFIG')
    raw.present? ? JSON.parse(raw) : default_config
  rescue JSON::ParserError
    default_config
  end

  def default_config
    {
      'vn_default' => 'payos',
      'vn_fallback' => ['sepay'],
      'intl_default' => 'payos',
      'intl_fallback' => ['sepay'],
      'enabled' => %w[payos sepay]
    }
  end
end
