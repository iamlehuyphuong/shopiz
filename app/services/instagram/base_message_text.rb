class Instagram::BaseMessageText < Instagram::WebhooksBaseService
  attr_reader :messaging

  def initialize(messaging, channel)
    @messaging = messaging
    super(channel)
  end

  def perform
    connected_instagram_id, contact_id = instagram_and_contact_ids
    inbox_channel(connected_instagram_id)

    if @inbox.blank?
      Rails.logger.warn("[Instagram] Inbox not found for connected_instagram_id: #{connected_instagram_id}")
      return
    end

    if @inbox.channel.reauthorization_required?
      Rails.logger.warn("[Instagram] Skipping message processing as reauthorization is required for inbox #{@inbox.id}")
      return
    end

    return unsend_message if message_is_deleted?

    ensure_contact(contact_id) if contacts_first_message?(contact_id)

    @message = create_message
    process_referral if @message.present?
  end

  private

  def process_referral
    referral = @messaging.dig(:message, :referral) || @messaging[:referral]
    return if referral.blank?

    @message.update(content_attributes: @message.content_attributes.merge(referral: referral))
    conversation = @message.conversation

    url = referral[:source_url]
    ad_id = referral[:ad_id]
    
    note_content = "Tin nhắn bắt nguồn từ Ads Instagram"
    note_content += ": #{ad_id}" if ad_id.present?
    note_content += " - #{url}" if url.present?

    conversation.messages.create!(
      content: note_content.strip,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :template,
      private: true
    )

    conversation.add_labels(['instagram-ad'])
  end

  def instagram_and_contact_ids
    if agent_message_via_echo?
      [@messaging[:sender][:id], @messaging[:recipient][:id]]
    else
      [@messaging[:recipient][:id], @messaging[:sender][:id]]
    end
  end

  def agent_message_via_echo?
    @messaging[:message][:is_echo].present?
  end

  def message_is_deleted?
    @messaging[:message][:is_deleted].present?
  end

  # if contact was present before find out contact_inbox to create message
  def contacts_first_message?(ig_scope_id)
    @contact_inbox = @inbox.contact_inboxes.where(source_id: ig_scope_id).last
    @contact_inbox.blank? && @inbox.channel.instagram_id.present?
  end

  def unsend_message
    message_to_delete = @inbox.messages.find_by(
      source_id: @messaging[:message][:mid]
    )
    return if message_to_delete.blank?

    message_to_delete.update!(deleted: true)
  end

  # Methods to be implemented by subclasses
  def ensure_contact(contact_id)
    raise NotImplementedError, "#{self.class} must implement #ensure_contact"
  end

  def create_message
    raise NotImplementedError, "#{self.class} must implement #create_message"
  end
end
