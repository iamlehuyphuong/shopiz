# Processes webhook events from Zalo OA
# Routes events to the appropriate service based on event_name
class Webhooks::ZaloEventsJob < ApplicationJob
  queue_as :default

  INCOMING_MESSAGE_EVENTS = %w[
    user_send_text user_send_image user_send_link user_send_audio
    user_send_video user_send_sticker user_send_location user_send_file
  ].freeze

  OUTGOING_ECHO_EVENTS = %w[
    oa_send_text oa_send_image oa_send_gif oa_send_file oa_send_sticker
  ].freeze

  DELIVERY_EVENTS = %w[user_received_message user_seen_message].freeze

  SUPPORTED_EVENTS = (
    INCOMING_MESSAGE_EVENTS +
    OUTGOING_ECHO_EVENTS +
    DELIVERY_EVENTS +
    %w[follow unfollow user_submit_info user_reacted_message]
  ).freeze

  def perform(params = {}, signature: '', post_body: '')
    return unless SUPPORTED_EVENTS.include?(params[:event_name])
    return unless validate_signature(params, post_body, signature)

    channel = find_channel(params)
    return unless channel

    process_event(channel, params)
  end

  private

  def validate_signature(params, post_body, signature)
    app_id = params[:app_id]
    timestamp = params[:timestamp]
    oa_secret_key = GlobalConfigService.load('ZALO_OA_SECRET_KEY', '')
    raw_verify = "#{app_id}#{post_body}#{timestamp}#{oa_secret_key}"

    hash = Digest::SHA256.hexdigest(raw_verify)
    signature == "mac=#{hash}"
  end

  def find_channel(params)
    oa_id = extract_oa_id(params)
    Channel::ZaloOa.find_by(oa_id: oa_id)
  end

  def extract_oa_id(params)
    event = params[:event_name]

    if DELIVERY_EVENTS.include?(event) || oa_send_from_chat_tool?(params)
      params[:sender][:id]
    elsif %w[follow unfollow].include?(event)
      params[:oa_id]
    else
      params[:recipient][:id]
    end
  end

  def process_event(channel, params) # rubocop:disable Metrics/CyclomaticComplexity
    inbox = channel.inbox
    safe_params = params.with_indifferent_access

    case params[:event_name]
    when *DELIVERY_EVENTS
      Zalo::DeliveryStatusService.new(inbox: inbox, params: safe_params).perform
    when *OUTGOING_ECHO_EVENTS
      Zalo::OutgoingMessageService.new(inbox: inbox, params: safe_params).perform if oa_send_from_chat_tool?(params)
    when 'follow'
      Zalo::FollowService.new(inbox: inbox, params: safe_params).perform
    when 'unfollow'
      Zalo::UnfollowService.new(inbox: inbox, params: safe_params).perform
    when 'user_submit_info'
      Zalo::UserInfoService.new(inbox: inbox, params: safe_params).perform
    when 'user_reacted_message'
      Zalo::ReactionService.new(inbox: inbox, params: safe_params).perform
    when *INCOMING_MESSAGE_EVENTS
      Zalo::IncomingMessageService.new(inbox: inbox, params: safe_params).perform
    end
  end

  def oa_send_from_chat_tool?(params)
    params[:event_name].start_with?('oa_') && params[:sender][:admin_id].present?
  end
end
