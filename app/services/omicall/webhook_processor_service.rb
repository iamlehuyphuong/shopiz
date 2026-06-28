class Omicall::WebhookProcessorService
  def initialize(payload)
    @payload = payload
  end

  def perform
    phone_number = @payload['phone_number']
    return unless phone_number.present?
    
    # Try to find contact matching the phone number across all accounts
    # This might match multiple contacts if the phone number exists in multiple accounts.
    contacts = Contact.where("phone_number LIKE ?", "%#{phone_number}%")
    return if contacts.empty?
    
    contacts.each do |contact|
      create_note_for_contact(contact)
    end
  end

  private

  def create_note_for_contact(contact)
    conversation = contact.conversations.order(created_at: :desc).first
    return unless conversation

    duration = @payload['duration'].to_i
    callbot = @payload['is_callbot']
    record_url = @payload['recording_file_url']
    direction = @payload['direction']

    direction_text = direction == 'outbound' ? 'đi' : 'đến'
    
    content = "📞 **Tóm tắt cuộc gọi #{direction_text} (OmiCall)**\n"
    content += "- Thời lượng đàm thoại: #{duration} giây\n"
    content += "- Gọi qua Callbot AI: #{callbot ? 'Có' : 'Không'}\n"
    content += "- Ghi âm: [Nghe lại cuộc gọi](#{record_url})\n" if record_url.present?

    Message.create!(
      conversation: conversation,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      private: true
    )
  end
end
