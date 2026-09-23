class Messages::MessageBuilder
  include ::FileTypeHelper
  include ::DataHelper

  attr_reader :message

  def initialize(user, conversation, params)
    @params = params
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @account = conversation.account
    @message_type = params[:message_type] || 'outgoing'
    @attachments = params[:attachments]
    @automation_rule = content_attributes&.dig(:automation_rule_id)
    return unless params.instance_of?(ActionController::Parameters)

    @in_reply_to = content_attributes&.dig(:in_reply_to)
    @items = content_attributes&.dig(:items)
  end

  def perform
    @message = @conversation.messages.build(message_params)
    process_attachments
    @message.save!
    @message
  end

  private

  # Extracts content attributes from the given params.
  # - Converts ActionController::Parameters to a regular hash if needed.
  # - Attempts to parse a JSON string if content is a string.
  # - Returns an empty hash if content is not present, if there's a parsing error, or if it's an unexpected type.
  def content_attributes
    params = convert_to_hash(@params)
    content_attributes = params.fetch(:content_attributes, {})

    return safe_parse_json(content_attributes) if content_attributes.is_a?(String)
    return content_attributes if content_attributes.is_a?(Hash)

    {}
  end

  def process_attachments
    return if @attachments.blank?

    @attachments.each do |uploaded_attachment|
      attachment = @message.attachments.build(
        account_id: @message.account_id
      )

      if uploaded_attachment.is_a?(String)
        attachment.file = uploaded_attachment
        attachment.file_type = file_type_by_signed_id(uploaded_attachment)
      else
        checksum = Digest::MD5.file(uploaded_attachment.tempfile.path).base64digest
        existing_blob = ActiveStorage::Blob.find_by(checksum: checksum, byte_size: uploaded_attachment.size)

        attachment.file = existing_blob || uploaded_attachment
        attachment.file_type = file_type(uploaded_attachment&.content_type)
      end
    end
  end

  def message_type
    # Allow incoming messages in both API and Voice channels
    if !['Channel::Api', 'Channel::Voice'].include?(@conversation.inbox.channel_type) && @message_type == 'incoming'
      raise StandardError, 'Incoming messages are only allowed in Api and Voice inboxes'
    end

    @message_type
  end

  def sender
    message_type == 'outgoing' ? (message_sender || @user) : @conversation.contact
  end

  def external_created_at
    @params[:external_created_at].present? ? { external_created_at: @params[:external_created_at] } : {}
  end

  def automation_rule_id
    @automation_rule.present? ? { content_attributes: { automation_rule_id: @automation_rule } } : {}
  end

  def campaign_id
    @params[:campaign_id].present? ? { additional_attributes: { campaign_id: @params[:campaign_id] } } : {}
  end

  def template_params
    @params[:template_params].present? ? { additional_attributes: { template_params: JSON.parse(@params[:template_params].to_json) } } : {}
  end

  def message_sender
    return if @params[:sender_type] != 'AgentBot'

    AgentBot.where(account_id: [nil, @conversation.account.id]).find_by(id: @params[:sender_id])
  end

  def message_params
    message_attrs = {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: @params[:content],
      private: @private,
      sender: sender,
      content_type: @params[:content_type],
      content_attributes: content_attributes.presence,
      items: @items,
      in_reply_to: @in_reply_to,
      echo_id: @params[:echo_id],
      source_id: @params[:source_id]
    }.merge(external_created_at).merge(automation_rule_id).merge(campaign_id).merge(template_params)

    # Directly add content_attributes from params if present
    message_attrs[:content_attributes] = content_attributes if @params[:content_attributes].present?

    # Stamp comment_id per-message for Facebook private reply to avoid race conditions
    # when multiple agents reply concurrently on the same conversation.
    stamp_facebook_comment_id(message_attrs)

    message_attrs
  end

  def stamp_facebook_comment_id(message_attrs)
    return unless @conversation.inbox&.channel_type == 'Channel::FacebookPage'
    return unless @message_type == 'outgoing' && !@private

    comment_id = @conversation.additional_attributes&.dig('comment_id')
    return if comment_id.blank?

    message_attrs[:content_attributes] ||= {}
    message_attrs[:content_attributes] = message_attrs[:content_attributes].merge('target_comment_id' => comment_id)
  end
end

Messages::MessageBuilder.prepend_mod_with('Messages::MessageBuilder')
