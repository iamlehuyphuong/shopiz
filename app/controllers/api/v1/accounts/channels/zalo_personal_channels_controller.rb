class Api::V1::Accounts::Channels::ZaloPersonalChannelsController < Api::V1::Accounts::BaseController
    def create
      oa_id = params[:oa_id]
      access_token = params[:access_token]
      refresh_token = params[:refresh_token]
      expires_in = params[:expires_in]
      inbox_name = params[:inbox_name]
      avatar_url = params[:avatar_url]
      zalo_inbox = nil
      
      ActiveRecord::Base.transaction do
        channel = Current.account.zalo_personals.create!(oa_id: oa_id, oa_access_token: access_token, refresh_token: refresh_token, expires_in: expires_in)
        zalo_inbox = Current.account.inboxes.create!(name: inbox_name, channel: channel)
        Avatar::AvatarFromUrlJob.perform_later(zalo_inbox, avatar_url)
      end
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
        # Auto parse format: IP:PORT:USER:PASS
        parts = proxy.split(':')
        if parts.length == 4
          ip, port, user, pass = parts
          proxy_url = "http://#{ip}:#{port}"
          
          # Send multiple standard variables to cover different Node.js implementations
          body[:proxy] = proxy_url
          body[:proxyUrl] = proxy_url
          body[:proxyUsername] = user
          body[:proxyPassword] = pass
          body[:proxy_username] = user
          body[:proxy_password] = pass
        else
          body[:proxy] = proxy
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