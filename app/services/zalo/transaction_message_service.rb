# Sends transaction messages via Zalo OA API
# Transaction messages are used for order updates, payment confirmations, shipping notifications, OTP, etc.
# Unlike CS messages, transaction messages can be sent anytime (not limited to 48h window)
# but require OA to have registered templates with Zalo
class Zalo::TransactionMessageService
  pattr_initialize [:channel!, :user_id!, :template!, :variables]

  def perform
    payload = template.build_payload(user_id, variables || {})
    response = client.send_transaction_message(payload)

    if response['error']&.zero?
      Rails.logger.info "Zalo::TransactionMessageService: sent template '#{template.template_name}' to user #{user_id}"
      { success: true, message_id: response.dig('data', 'message_id') }
    else
      Rails.logger.error "Zalo::TransactionMessageService: failed to send template '#{template.template_name}' " \
                         "to user #{user_id}: #{response['message']}"
      { success: false, error: response['message'], error_code: response['error'] }
    end
  end

  private

  def client
    @client ||= channel.client
  end
end
