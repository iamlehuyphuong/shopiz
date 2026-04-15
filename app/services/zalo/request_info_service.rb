# Sends a "Request User Info" form to a Zalo user via OA
# This asks the user to share their personal information (phone, address, etc.)
# User must explicitly agree — this is Zalo's opt-in privacy mechanism
#
# The user's response will arrive via 'user_submit_info' webhook event,
# which is handled by Zalo::UserInfoService
#
# Usage:
#   Zalo::RequestInfoService.new(channel: channel, user_id: '123').request_phone
#   Zalo::RequestInfoService.new(channel: channel, user_id: '123').request_all
class Zalo::RequestInfoService
  pattr_initialize [:channel!, :user_id!]

  # Request phone number only
  def request_phone
    send_info_request(
      subtitle: 'Vui lòng chia sẻ số điện thoại để chúng tôi hỗ trợ bạn tốt hơn',
      fields: ['phone']
    )
  end

  # Request address only
  def request_address
    send_info_request(
      subtitle: 'Vui lòng chia sẻ địa chỉ để chúng tôi phục vụ bạn tốt hơn',
      fields: ['address']
    )
  end

  # Request all available info (phone + address + name)
  def request_all
    send_info_request(
      subtitle: 'Vui lòng chia sẻ thông tin để chúng tôi phục vụ bạn tốt hơn',
      fields: %w[phone address name]
    )
  end

  private

  def client
    @client ||= channel.client
  end

  def send_info_request(subtitle:, fields: [])
    body = {
      recipient: { user_id: user_id },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'request_user_info',
            elements: [{
              title: channel.inbox&.name || 'Thông tin cá nhân',
              subtitle: subtitle,
              image_url: channel.inbox&.avatar_url
            }.compact]
          }
        }
      }
    }

    response = client.send_cs_message(body)

    if response['error']&.zero?
      Rails.logger.info "Zalo::RequestInfoService: sent info request to user #{user_id}"
      { success: true }
    else
      Rails.logger.error "Zalo::RequestInfoService: failed to request info from user #{user_id}: #{response['message']}"
      { success: false, error: response['message'] }
    end
  end
end
