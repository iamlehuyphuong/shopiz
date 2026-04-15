class Facebook::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Facebook' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    campaign.completed!

    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    process_audience(audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    contacts.each do |contact|
      contact_inbox = inbox.contact_inboxes.find_by(contact_id: contact.id)
      next unless contact_inbox

      optin = ContactOptin.where(contact_id: contact.id, inbox_id: inbox.id, status: :active)
                          .where('expires_at IS NULL OR expires_at > ?', Time.current)
                          .first

      next unless optin

      process_contact(contact, contact_inbox, optin.token)
    end
  end

  def process_contact(contact, contact_inbox, token)
    conversation = find_or_build_conversation(contact_inbox)
    content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)

    conversation.messages.create!(
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      message_type: :outgoing,
      content: content,
      content_attributes: { notification_messages_token: token }
    )
  end

  def find_or_build_conversation(contact_inbox)
    if inbox.lock_to_single_conversation
      Conversation.where(
        account_id: campaign.account_id,
        inbox_id: inbox.id,
        contact_id: contact_inbox.contact_id
      ).order(created_at: :desc).first || build_conversation(contact_inbox)
    else
      Conversation.where(
        account_id: campaign.account_id,
        inbox_id: inbox.id,
        contact_id: contact_inbox.contact_id
      ).where.not(status: :resolved).order(created_at: :desc).first || build_conversation(contact_inbox)
    end
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
