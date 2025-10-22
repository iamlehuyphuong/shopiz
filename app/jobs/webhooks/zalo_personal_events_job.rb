class Webhooks::ZaloPersonalEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {}, signature: '', post_body: '')
    oa_id = params[:_accountId]
    channel = Channel::ZaloPersonal.find_by(oa_id: oa_id)
    Rails.logger.info("Zalo Personal webhook received events for channel: #{channel&.id}, oa_id: #{oa_id}")
    return unless channel

    process_event_params(channel, params)
  end

  private

  def validate_signature(params, post_body, signature)
    app_id = params[:app_id]
    timestamp = params[:timestamp]
    oa_secret_key = ENV.fetch('ZALO_OA_SECRET_KEY', nil)
    raw_verify = "#{app_id}#{post_body}#{timestamp}#{oa_secret_key}"

    hash = Digest::SHA256.hexdigest(raw_verify)
    signature == "mac=#{hash}"
  end

  def process_event_params(channel, params)
    if delivery_event?(params)
      ZaloPersonal::DeliveryStatusService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    elsif outgoing_event?(params)
      ZaloPersonal::OutgoingMessageService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    else
      ZaloPersonal::IncomingMessageService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    end
  end

  def delivery_event?(params)
    params[:data][:msgType] == 'chat.reaction'
  end

  def outgoing_event?(params)
    params[:isSelf] == true
  end
end
