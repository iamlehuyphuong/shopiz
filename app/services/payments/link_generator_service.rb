class Payments::LinkGeneratorService
  def initialize(order:, provider_name: nil)
    @order = order
    @provider_name = provider_name.presence || order.payment_method.presence || 'tingee'
  end

  def perform
    return { success: false, error: "Order ##{@order.id} is already paid." } if @order.paid?

    # If there is already a checkout link, we can just return it
    if @order.payment_transaction_id.present? && @order.payment_qr_url.present? && @order.unpaid?
      return { success: true, checkout_url: @order.payment_qr_url, transaction_id: @order.payment_transaction_id,
               provider_name: @order.payment_provider }
    end

    # Save the selected payment method to the order if changed
    @order.update!(payment_method: @provider_name) unless @order.payment_method == @provider_name

    provider_class = Payments::ProviderRegistry.provider_for(@provider_name)
    return { success: false, error: "Payment provider '#{@provider_name}' is not supported." } unless provider_class

    config = @order.account.sales_payment_config&.dig(@provider_name) || {}
    return { success: false, error: "Payment provider '#{@provider_name}' is not configured." } if config.blank?

    provider = provider_class.new(config)

    transaction_id = "ORDER#{@order.id}T#{Time.current.to_i}"
    amount = @order.total_amount.to_i
    description = "Thanh toan don hang #{@order.id}"
    return_url = ENV.fetch('FRONTEND_URL', 'https://shopiz.pro')

    result = provider.create_checkout(
      amount: amount,
      order_id: transaction_id,
      description: description,
      return_url: return_url
    )

    checkout_link = case @provider_name
                    when 'sepay'
                      "#{return_url}/api/v1/payments/sepay_checkout/#{transaction_id}"
                    else
                      result[:checkout_url]
                    end

    return { success: false, error: 'Failed to generate payment link.' } if checkout_link.blank?

    @order.update!(
      payment_provider: @provider_name,
      payment_transaction_id: transaction_id,
      payment_qr_url: checkout_link
    )

    # Enqueue expiration check (15 minutes)
    Payments::CheckExpiredPaymentJob.set(wait: 15.minutes).perform_later(@order.id)

    { success: true, checkout_url: checkout_link, transaction_id: transaction_id, provider_name: @provider_name }
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    { success: false, error: "Failed to create payment link: #{e.message}" }
  end
end
