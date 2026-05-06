# frozen_string_literal: true

# Central service for resolving which payment gateway to use
# Based on account locale (VN vs international) and configured routing rules
class Enterprise::Billing::PaymentRouter
  METHODS = %w[payos sepay polar].freeze

  def initialize(account)
    @account = account
  end

  # Returns the best payment method for this account
  def resolve
    default_m = default_method
    return default_m if enabled?(default_m)

    fallback_chain.first || METHODS.first
  end

  # Returns ordered list of available methods for this account's region
  def available_methods
    ([default_method] + fallback_chain).uniq.select { |m| enabled?(m) }
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
    val = GlobalConfig.get_value("PAYMENT_GATEWAY_#{method.upcase}_ENABLED")
    # By default, payos and sepay are enabled for safe operation if DB not seeded
    val.nil? ? %w[payos sepay].include?(method) : val.to_s == 'true'
  end

  def default_method
    if vietnam_account?
      GlobalConfig.get_value('PAYMENT_GATEWAY_VN_DEFAULT').presence || 'payos'
    else
      GlobalConfig.get_value('PAYMENT_GATEWAY_INTL_DEFAULT').presence || 'polar'
    end
  end

  def fallback_chain
    # The fallback logic: All *other* payment methods that are currently enabled
    enabled_methods = METHODS.select { |m| enabled?(m) }
    enabled_methods - [default_method]
  end

  def vietnam_account?
    locale = @account.locale || 'vi'
    locale == 'vi'
  end
end
