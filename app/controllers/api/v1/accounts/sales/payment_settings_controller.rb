class Api::V1::Accounts::Sales::PaymentSettingsController < Api::V1::Accounts::BaseController
  def test_payment
    provider_name = Current.account.sales_payment_config&.dig('default_provider')
    
    if provider_name.blank?
      return render json: { error: 'Bạn cần cấu hình kênh thanh toán mặc định trước khi test' }, status: :unprocessable_entity
    end

    config = Current.account.sales_payment_config&.dig(provider_name)
    unless config && (config['active'] == true || config['active'] == 'true')
      return render json: { error: 'Kênh thanh toán mặc định chưa được bật' }, status: :unprocessable_entity
    end

    provider_class = Payments::ProviderRegistry.provider_for(provider_name)
    unless provider_class
      return render json: { error: 'Kênh thanh toán không được hỗ trợ' }, status: :unprocessable_entity
    end

    provider = provider_class.new(config.deep_symbolize_keys)
    
    begin
      checkout_url = provider.create_checkout(
        amount: 10000,
        order_id: Time.current.to_i, # unique int ID for PayOS
        description: "Test thanh toan Shopiz",
        return_url: "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{Current.account.id}/sales/payment?status=PAID",
        cancel_url: "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{Current.account.id}/sales/payment?status=CANCELLED"
      )
      render json: { checkout_url: checkout_url }
    rescue => e
      render json: { error: "Lỗi tạo thanh toán: #{e.message}" }, status: :unprocessable_entity
    end
  end
end
