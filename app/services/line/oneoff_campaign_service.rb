class Line::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" unless line_campaign? && campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    campaign.completed!
    process_audience(extract_audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def line_campaign?
    campaign.inbox.inbox_type == 'Line'
  end

  def extract_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true).to_a
    valid_contacts = contacts.select do |contact|
      contact_inbox = inbox.contact_inboxes.find_by(contact_id: contact.id)
      contact_inbox&.source_id.present?
    end

    if has_liquid_variables?(campaign.message)
      # Process 1-1 if personalized
      valid_contacts.each { |contact| process_contact(contact) }
    else
      # Process Batch via Multicast if identical
      valid_contacts.each_slice(500) { |batch| process_batch(batch) }
    end
  end

  def has_liquid_variables?(text)
    text.include?('{{') && text.include?('}}')
  end

  def process_batch(contacts)
    contact_inboxes = inbox.contact_inboxes.where(contact_id: contacts.map(&:id))
    user_ids = contact_inboxes.pluck(:source_id)
    
    # Limit of Multicast API is 500
    message_payload = {
      type: 'text',
      text: campaign.message
    }
    
    response = channel.client.multicast(user_ids, message_payload)
    parsed_response = JSON.parse(response.body) rescue {}
    
    if response.code == '200'
      campaign.increment_metric!(:delivered, contacts.size)
      bulk_create_messages(contacts, contact_inboxes)
    else
      campaign.increment_metric!(:failed, contacts.size)
      Rails.logger.error "Line::OneoffCampaignService: Error processing batch: #{parsed_response}"
    end
  end

  def process_contact(contact)
    contact_inbox = inbox.contact_inboxes.find_by(contact_id: contact.id)
    conversation = find_or_build_conversation(contact_inbox)
    content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)

    # Creating a message triggers SendReplyJob (via Line::SendOnLineService)
    conversation.messages.create!(
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      message_type: :outgoing,
      content: content,
      additional_attributes: { campaign_id: campaign.id }
    )
    campaign.increment_metric!(:delivered)
  end

  def bulk_create_messages(contacts, contact_inboxes)
    contacts.each do |contact|
      contact_inbox = contact_inboxes.find { |ci| ci.contact_id == contact.id }
      next unless contact_inbox

      conversation = find_or_build_conversation(contact_inbox)
      msg = conversation.messages.build(
        account_id: campaign.account_id,
        inbox_id: campaign.inbox_id,
        message_type: :outgoing,
        content: campaign.message,
        additional_attributes: { campaign_id: campaign.id }
      )
      # Skip execute_after_create_commit_callbacks so it doesn't trigger SendReplyJob (since Multicast sent it)
      msg.loaded_from_history = true
      msg.save!
    end
  end

  def find_or_build_conversation(contact_inbox)
    base_query = Conversation.where(
      account_id: campaign.account_id,
      inbox_id: inbox.id,
      contact_id: contact_inbox.contact_id
    )
    
    conversation = if inbox.lock_to_single_conversation
                     base_query.order(created_at: :desc).first
                   else
                     base_query.where.not(status: :resolved).order(created_at: :desc).first
                   end
                   
    conversation || build_conversation(contact_inbox)
  end

  def build_conversation(contact_inbox)
    Conversation.create!(
      account_id: campaign.account_id,
      inbox_id: inbox.id,
      contact_inbox_id: contact_inbox.id,
      contact_id: contact_inbox.contact_id
    )
  end
end
