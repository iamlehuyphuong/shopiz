class Api::V1::Accounts::Channels::TiktokChannelsController < Api::V1::Accounts::BaseController
  def create
    @channel_data = data_from_redis
    tiktok_inbox = nil

    ActiveRecord::Base.transaction do
      channel = Current.account.tiktoks.create!(@channel_data)
      tiktok_inbox = Current.account.inboxes.create!(name: params[:shop_name], channel: channel)
    end

    @redis.del("tiktok_session:#{params[:tiktok_session_id]}")
    render json: tiktok_inbox.as_json
  rescue StandardError => e
    handle_exception(e)
  end

  private

  def handle_exception(exception)
    ChatwootExceptionTracker.new(exception).capture_exception
    Rails.logger.error "Error in create inbox for tiktok channel: #{exception.message}"
    log_additional_info
  end

  def log_additional_info
    Rails.logger.debug do
      "#{@channel_data.to_json}, shop_name: #{params[:shop_name]}"
    end
  end

  def data_from_redis
    @redis = Redis.new(url: ENV["REDIS_URL"])
    channel_data_json = @redis.get("tiktok_session:#{params[:tiktok_session_id]}")

    JSON.parse(channel_data_json)
  end
end
