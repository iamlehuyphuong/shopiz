class Api::V1::Accounts::Channels::ZaloPersonalChannelsController < Api::V1::Accounts::BaseController
  def create
    oa_id = params[:oa_id]
    access_token = params[:access_token]
    refresh_token = params[:refresh_token]
    expires_in = params[:expires_in]
    inbox_name = params[:inbox_name]
    avatar_url = params[:avatar_url]
    proxy_used = params[:proxy_used]
    zalo_inbox = nil

    ActiveRecord::Base.transaction do
      channel = Current.account.zalo_personals.create!(
        oa_id: oa_id,
        oa_access_token: access_token,
        refresh_token: refresh_token,
        expires_in: expires_in,
        provider_config: { proxy_used: proxy_used }.compact
      )
      zalo_inbox = Current.account.inboxes.create!(name: inbox_name, channel: channel)
      Avatar::AvatarFromUrlJob.perform_later(zalo_inbox, avatar_url)
    end

    # Automatically sync friends after successful connection
    ZaloPersonal::SyncFriendsJob.perform_later(zalo_inbox.id) if zalo_inbox

    render json: zalo_inbox.as_json
  rescue StandardError => e
    handle_exception(e)
    render json: { message: e.message }, status: :unprocessable_entity
  end

  def generate_qr
    proxy = params[:proxy]
    url = "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/zalo-login"

    body = {}
    if proxy.present?
      if proxy.start_with?('http://', 'https://', 'socks4://', 'socks5://')
        body[:proxy] = proxy
      else
        # Auto parse format: IP:PORT:USER:PASS or IP:PORT
        parts = proxy.split(':')
        if parts.length == 4
          ip, port, user, pass = parts
          body[:proxy] = "http://#{user}:#{pass}@#{ip}:#{port}"
        elsif parts.length == 2
          body[:proxy] = "http://#{proxy}"
        else
          body[:proxy] = proxy
        end
      end
    end

    response = HTTParty.post(
      url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )

    render json: response.parsed_response
  rescue StandardError => e
    handle_exception(e)
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def find_user
    inbox = Current.account.inboxes.find_by(id: params[:inbox_id])
    return render json: { error: 'Inbox not found' }, status: :not_found unless inbox&.channel&.is_a?(Channel::ZaloPersonal)

    url = "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/findUser"

    phone = params[:phone]
    # Clean up phone if needed, but we pass it exactly as it is for now
    body = {
      phoneNumber: phone,
      ownId: inbox.channel.oa_id
    }

    response = HTTParty.post(
      url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )

    if response['success']
      user_info = response['data'] || {}

      gender_str = case user_info['gender']
                   when 0 then 'Nam'
                   when 1 then 'Nữ'
                   else 'Chưa cập nhật'
                   end

      render json: {
        data: {
          name: user_info['zaloName'] || user_info['displayName'] || user_info['zalo_name'] || user_info['display_name'],
          avatar: user_info['avatar'],
          cover: user_info['cover'],
          bio: user_info['status'],
          gender: gender_str,
          dob: user_info['sdob']
        }
      }
    else
      render json: { error: response['message'] || 'User not found' }, status: :not_found
    end
  rescue StandardError => e
    handle_exception(e)
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def handle_exception(exception)
    ChatwootExceptionTracker.new(exception).capture_exception
    Rails.logger.error "Error in create inbox for zalo personal channel: #{exception.message}"
    log_additional_info
  end

  def log_additional_info
    Rails.logger.debug do
      "oa_id: #{params[:oa_id]}, inbox_name: #{params[:inbox_name]} ,
        oa_access_token: #{params[:access_token]} , refresh_token: #{params[:refresh_token]} , expires_in: #{params[:expires_in]}"
    end
  end
end
