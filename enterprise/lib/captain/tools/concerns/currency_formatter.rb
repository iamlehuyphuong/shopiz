module Captain::Tools::Concerns::CurrencyFormatter
  extend ActiveSupport::Concern

  def format_currency(amount, currency = 'VND')
    return "0 #{currency}" if amount.blank?

    # Format with ActiveSupport if available, else simple fallback
    if defined?(ActiveSupport::NumberHelper)
      ActiveSupport::NumberHelper.number_to_currency(amount, unit: currency, format: '%n %u', precision: 0)
    else
      "#{amount} #{currency}"
    end
  end
end
