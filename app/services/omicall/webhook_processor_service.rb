class Omicall::WebhookProcessorService
  def initialize(payload)
    @payload = payload
  end

  def perform
    # Chỉ xử lý Webhook khi cuộc gọi đã kết thúc (CDR)
    return unless @payload['state'] == 'cdr' || @payload['state'].blank?

    phone_number = @payload['phone_number']
    return if phone_number.blank?

    # Try to find contact matching the phone number across all accounts
    # This might match multiple contacts if the phone number exists in multiple accounts.
    contacts = Contact.where('phone_number LIKE ?', "%#{phone_number}%")
    return if contacts.empty?

    contacts.each do |contact|
      create_note_for_contact(contact)
    end
  end

  private

  def create_note_for_contact(contact)
    conversation = contact.conversations.order(created_at: :desc).first
    return unless conversation

    duration = @payload['bill_sec'].to_i
    answer_sec = @payload['answer_sec'].to_i
    callbot = @payload['is_callbot']
    record_url = @payload['recording_file'].presence || @payload['recording_file_url']
    direction = @payload['direction']
    transaction_id = @payload['transaction_id']
    note = @payload['note']
    tags = @payload['tag'] || []

    direction_key = direction == 'outbound' ? 'outbound' : 'inbound'
    locale = conversation.account.locale || I18n.default_locale
    direction_text = I18n.t("omicall.direction.#{direction_key}", locale: locale)

    is_missed = answer_sec.zero?

    translation_key = if is_missed
                        'conversations.activity.omicall.missed_call'
                      elsif record_url.present?
                        'conversations.activity.omicall.call_summary'
                      else
                        'conversations.activity.omicall.call_summary_no_record'
                      end

    callbot_text = I18n.t("omicall.callbot.#{callbot ? 'yes' : 'no'}", locale: locale)

    content_attributes = {
      translation_key: translation_key,
      translation_values: {
        direction_text: direction_text,
        duration: duration,
        callbot: callbot_text,
        record_url: record_url
      }
    }

    if transaction_id.present?
      source_id = "omicall_#{transaction_id}"
      existing_message = conversation.messages.find_by(source_id: source_id)
      
      if existing_message
        existing_message.update!(content_attributes: existing_message.content_attributes.merge(content_attributes))
      else
        Message.create!(
          conversation: conversation,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          message_type: :activity,
          source_id: source_id,
          content: '',
          content_attributes: content_attributes
        )
      end
    else
      Message.create!(
        conversation: conversation,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: '',
        content_attributes: content_attributes
      )
    end

    if note.present?
      contact.notes.create!(
        account_id: conversation.account_id,
        content: "OMICall: #{note}"
      )
    end

    if tags.present? && tags.any?
      lowercase_tags = tags.map(&:downcase)
      existing_labels = conversation.account.labels.where(title: lowercase_tags).pluck(:title)
      conversation.add_labels(existing_labels) if existing_labels.any?
    end
  end
end
