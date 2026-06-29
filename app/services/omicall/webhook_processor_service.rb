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
    record_url = @payload['recording_file_url']
    direction = @payload['direction']

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

    Message.create!(
      conversation: conversation,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: '',
      content_attributes: {
        translation_key: translation_key,
        translation_values: {
          direction_text: direction_text,
          duration: duration,
          callbot: callbot_text,
          record_url: record_url
        }
      }
    )
  end
end
