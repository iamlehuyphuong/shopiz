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
    oa_secret_key = ENV.fetch('ZALO_SECRET_KEY', nil)
    raw_verify = "#{app_id}#{post_body}#{timestamp}#{oa_secret_key}"

    hash = Digest::SHA256.hexdigest(raw_verify)
    signature == "mac=#{hash}"
  end

  def process_event_params(channel, params)
    if undo_message?(params)
      handle_undo_message(channel, params)
    elsif delivery_event?(params)
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

  def undo_message?(params)
    params[:data][:msgType] == 'chat.undo'
  end

  def outgoing_event?(params)
    params[:isSelf] == true
  end

  def handle_undo_message(channel, params)
    message = find_message(channel, params)
    return unless message

    message.update!(content: I18n.t('conversations.messages.undo'), content_type: :text, content_attributes: { undo: true })
    message.attachments.destroy_all
  end

  def find_message(channel, params)
    global_msg_id = params.dig(:data, :content, :globalMsgId).to_s
    client_msg_id = params.dig(:data, :content, :cliMsgId).to_s
    conditions = []
    query_params = {}

    if global_msg_id != '0'
      conditions << <<~SQL.squish
        source_id = :global_msg_id OR additional_attributes ->> 'msgId' = :global_msg_id
      SQL
      query_params[:global_msg_id] = global_msg_id
    end

    if client_msg_id != '0'
      conditions << "additional_attributes ->> 'cliMsgId' = :client_msg_id"
      query_params[:client_msg_id] = client_msg_id
    end

    channel.inbox.messages.find_by(conditions.join(' OR '), query_params) if conditions.any?
  end
end
