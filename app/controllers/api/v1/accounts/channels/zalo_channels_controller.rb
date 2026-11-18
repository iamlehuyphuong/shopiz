class Api::V1::Accounts::Channels::ZaloChannelsController < Api::V1::Accounts::BaseController
  def exchange_token
    response = HTTParty.post(
      'https://oauth.zaloapp.com/v4/oa/access_token',
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'secret_key' => GlobalConfigService.load('ZALO_OA_APP_SECRET', '')
      },
      body: {
        code: params[:code],
        app_id: GlobalConfigService.load('ZALO_OA_APP_ID', ''),
        grant_type: 'authorization_code'
      }
    )
    render json: response.parsed_response.slice('access_token', 'refresh_token', 'expires_in', 'error', 'error_name', 'error_description')
  end

  def create
    oa_id = params[:oa_id]
    access_token = params[:access_token]
    refresh_token = params[:refresh_token]
    expires_in = params[:expires_in]
    inbox_name = params[:inbox_name]
    avatar_url = params[:avatar_url]
    zalo_inbox = nil

    ActiveRecord::Base.transaction do
      channel = Current.account.zalo_oas.create!(oa_id: oa_id, oa_access_token: access_token, refresh_token: refresh_token, expires_in: expires_in)
      zalo_inbox = Current.account.inboxes.create!(name: inbox_name, channel: channel)
      @channel = channel
      @zalo_inbox = zalo_inbox
    end

    if avatar_url.blank?
      begin
        response = HTTParty.get(
          'https://openapi.zalo.me/v3.0/oa/getoa',
          headers: { 'access_token' => access_token }
        )
        avatar_url = response.dig('data', 'avatar') if response.success? && response['error'].to_i == 0
      rescue StandardError => e
        Rails.logger.error("Failed to fetch Zalo OA profile for avatar: #{e.message}")
      end
    end

    Avatar::AvatarFromUrlJob.perform_later(@zalo_inbox, avatar_url) if avatar_url.present?
    Zalo::SyncConversationsJob.perform_later(@channel)
    Zalo::SyncFollowersJob.perform_later(@channel)

    render json: @zalo_inbox.as_json
  rescue StandardError => e
    handle_exception(e)
    render json: { message: e.message }, status: :unprocessable_entity
  end

  private

  def handle_exception(exception)
    ChatwootExceptionTracker.new(exception).capture_exception
    Rails.logger.error "Error in create inbox for zalo oa channel: #{exception.message}"
    log_additional_info
  end

  def log_additional_info
    Rails.logger.debug do
      "oa_id: #{params[:oa_id]}, inbox_name: #{params[:inbox_name]} ,
        oa_access_token: #{params[:access_token]} , refresh_token: #{params[:refresh_token]} , expires_in: #{params[:expires_in]}"
    end
  end
end
