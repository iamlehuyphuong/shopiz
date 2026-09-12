class Captain::Tools::CreatePaymentLinkTool < Captain::Tools::BasePublicTool
  description 'Create a payment link for the customer to pay for their order.'
  param :payment_method, type: 'string', desc: 'The payment method to use (e.g. tingee, sepay, payos)', required: false

  def perform(tool_context, payment_method: 'tingee')
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    # Find the latest draft or unpaid order for this conversation
    order = conversation.conversation_orders.ordered.first
    return 'No active order found for this conversation. Please create an order first.' unless order
    return "Order ##{order.id} is already paid." if order.paid?
    
    provider_name = payment_method.presence || 'tingee'
    
    # Save the selected payment method to the order
    order.update!(payment_method: provider_name) unless order.payment_method == provider_name
    
    provider_class = Payments::ProviderRegistry.provider_for(provider_name)
    return "Payment provider '#{provider_name}' is not supported." unless provider_class

    config = order.account.settings['sales_payment_config']&.dig(provider_name) || {}
    provider = provider_class.new(config)

    transaction_id = "ORDER#{order.id}T#{Time.current.to_i}"
    amount = order.total_amount.to_i
    description = "Thanh toan don hang #{order.id}"
    return_url = ENV.fetch('FRONTEND_URL', 'https://shopiz.pro')

    result = provider.create_checkout(
      amount: amount,
      order_id: transaction_id,
      description: description,
      return_url: return_url
    )

    checkout_link = if provider_name == 'sepay'
                      "#{return_url}/api/v1/payments/sepay_checkout/#{transaction_id}"
                    else
                      result[:checkout_url]
                    end

    return 'Failed to generate payment link.' if checkout_link.blank?

    order.update!(
      payment_provider: provider_name,
      payment_transaction_id: transaction_id,
      payment_qr_url: checkout_link
    )
    
    # Enqueue expiration check (15 minutes)
    Payments::CheckExpiredPaymentJob.set(wait: 15.minutes).perform_later(order.id)

    log_tool_usage('create_payment_link', { conversation_id: conversation.id, order_id: order.id, provider: provider_name })

    "Payment link generated successfully: #{checkout_link}. Please send this link to the customer and ask them to pay."
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    "Failed to create payment link: #{e.message}"
  end
end
