class Webhooks::ZaloPersonalEventsJob < ApplicationJob
  queue_as :default

  retry_on Down::ConnectionError, Down::TimeoutError, wait: 5.seconds, attempts: 3

  def perform(params = {}, signature: '', post_body: '')
    params = deep_scrub(params).with_indifferent_access
    oa_id = params[:_accountId]
    channel = Channel::ZaloPersonal.find_by(oa_id: oa_id)
    Rails.logger.info("Zalo Personal webhook received events for channel: #{channel&.id}, oa_id: #{oa_id}, params: #{params.to_json}")
    return unless channel

    process_event_params(channel, params)
  end

  private

  def deep_scrub(value)
    case value
    when ActionController::Parameters, Hash
      value.to_h.transform_values { |v| deep_scrub(v) }
    when Array
      value.map { |v| deep_scrub(v) }
    when String
      value.scrub('')
    else
      value
    end
  end

  def validate_signature(params, post_body, signature)
    app_id = params[:app_id]
    timestamp = params[:timestamp]
    oa_secret_key = ENV.fetch('ZALO_SECRET_KEY', nil)
    raw_verify = "#{app_id}#{post_body}#{timestamp}#{oa_secret_key}"

    hash = Digest::SHA256.hexdigest(raw_verify)
    signature == "mac=#{hash}"
  end

  def process_event_params(channel, params) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    event_params = normalize_payload(params)

    case event_params[:_eventType]
    when 'undo'
      handle_undo_message(channel, event_params)
    when 'reaction'
      ZaloPersonal::DeliveryStatusService.new(inbox: channel.inbox, params: event_params).perform
    when 'group_event'
      ZaloPersonal::GroupEventService.new(inbox: channel.inbox, params: event_params).perform
    when 'message'
      if outgoing_event?(event_params)
        ZaloPersonal::OutgoingMessageService.new(inbox: channel.inbox, params: event_params).perform
      else
        ZaloPersonal::IncomingMessageService.new(inbox: channel.inbox, params: event_params).perform
      end
    end
  end

  def normalize_payload(params)
    return params unless params[:data].is_a?(Hash)

    normalized = params.merge(params[:data])
    
    if normalized.dig(:propertyExt, :type).present?
      normalized[:type] = normalized.dig(:propertyExt, :type).to_i
    end

    normalized.with_indifferent_access
  end

  def outgoing_event?(params)
    params[:uidFrom].to_s == params[:_accountId].to_s || params[:isSelf] == true
  end

  def handle_undo_message(channel, params)
    message = find_message(channel, params)
    return unless message

    message.update!(undo: true)
  end

  def find_message(channel, params)
    content_hash = params[:content].is_a?(Hash) ? params[:content].with_indifferent_access : {}
    msg_id = content_hash[:globalMsgId].to_s
    msg_id = params[:msgId].to_s if msg_id.blank? || msg_id == '0'
    cli_msg_id = content_hash[:cliMsgId].to_s

    ids_to_check = [msg_id, cli_msg_id].reject(&:blank?)
    return nil if ids_to_check.empty?

    channel.inbox.messages.find_by(
      "source_id IN (?) OR additional_attributes ->> 'msgId' IN (?)",
      ids_to_check,
      ids_to_check
    )
  end
end
