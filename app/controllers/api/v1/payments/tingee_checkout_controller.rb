class Api::V1::Payments::TingeeCheckoutController < ApplicationController
  skip_before_action :set_current_user, raise: false

  def show
    @order = ConversationOrder.find_by!(payment_transaction_id: params[:id])
    account = @order.account
    config = account.sales_payment_config&.dig('tingee') || {}
    bank_bin = config['bank_bin']
    account_number = config['account_number']
    client_id = config['client_id']
    api_key = config['api_key']

    if bank_bin.blank? || account_number.blank? || client_id.blank? || api_key.blank?
      render plain: 'Cổng thanh toán Tingee chưa được cấu hình đầy đủ.', status: :bad_request
      return
    end

    amount = @order.total_amount.to_i
    content = @order.payment_transaction_id

    begin
      if @order.payment_qr_data.present?
        @qr_base64 = "data:image/png;base64,#{@order.payment_qr_data}"
      else
        provider = Payments::Providers::TingeeProvider.new(config)
        @qr_base64 = provider.generate_static_qr(
          bank_bin: bank_bin,
          account_number: account_number,
          amount: amount,
          content: content
        )

        # Cache it if missing
        if @qr_base64.present?
          base64_data = @qr_base64.start_with?('data:image') ? @qr_base64.split(',').last : @qr_base64
          @order.update_column(:payment_qr_data, base64_data)
        end
      end
      render layout: false
    rescue StandardError => e
      render plain: "Lỗi tạo mã QR: #{e.message}", status: :internal_server_error
    end
  end
end
