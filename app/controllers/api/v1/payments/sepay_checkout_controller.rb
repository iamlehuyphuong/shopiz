class Api::V1::Payments::SepayCheckoutController < ApplicationController
  skip_before_action :set_current_user, raise: false

  def show
    @order = ConversationOrder.find_by!(payment_transaction_id: params[:id])
    account = @order.account
    config = account.settings['sales_payment_config']&.dig('sepay') || {}
    company_code = config['company_code']
    secret_key = config['secret_key']

    if company_code.blank? || secret_key.blank?
      render plain: 'Cổng thanh toán SePay chưa được cấu hình đầy đủ.', status: :bad_request
      return
    end

    provider = Payments::Providers::SepayProvider.new(config)

    amount = @order.total_amount.to_i
    # We pass the payment_transaction_id to SePay
    order_id = @order.payment_transaction_id
    description = "Thanh toan don hang #{@order.id}"
    return_url = ENV.fetch('FRONTEND_URL', 'https://shopiz.pro')

    result = provider.create_checkout(
      amount: amount,
      order_id: order_id,
      description: description,
      return_url: return_url
    )

    # SepayProvider#create_checkout currently uses Sepay::Client which returns form_params.
    # However, Sepay::Client actually returns a hash containing checkout_url and form_params,
    # and SepayProvider#create_checkout returns that directly.
    @checkout_url = result[:checkout_url]
    @form_params = result[:form_params]

    render layout: false
  end
end
