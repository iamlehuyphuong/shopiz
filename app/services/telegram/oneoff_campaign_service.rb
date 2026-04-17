class Telegram::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" unless telegram_campaign? && campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    campaign.completed!
    process_audience(extract_audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def telegram_campaign?
    campaign.inbox.inbox_type == 'Telegram'
  end

  def extract_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    contacts.each do |contact|
      contact_inbox = inbox.contact_inboxes.find_by(contact_id: contact.id)
      next unless contact_inbox
      # Ensure there's a valid chat_id for telegram
      next unless contact_inbox.source_id.present?

      campaign.increment_metric!(:total_sent)
      begin
        process_contact(contact, contact_inbox)
        # Sleep slightly to throttle to ~25 msg/sec ensuring we don't hit Telegram's 30 msg/sec limit
        sleep(0.04)
      rescue StandardError => e
        campaign.increment_metric!(:failed)
        Rails.logger.error "Telegram::OneoffCampaignService: Error processing contact #{contact.id}: #{e.message}"
      end
    end
  end

  def process_contact(contact, contact_inbox)
    conversation = find_or_build_conversation(contact_inbox)
    content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)

    # Creating a message automatically queues a SendReplyJob which calls Telegram::SendOnTelegramService
    conversation.messages.create!(
      account_id: campaign.account_id,
      inbox_id: campaign.inbox_id,
      message_type: :outgoing,
      content: content,
      additional_attributes: { campaign_id: campaign.id }
    )
    campaign.increment_metric!(:delivered)
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
      contact_id: contact_inbox.contact_id,
      additional_attributes: { chat_id: contact_inbox.source_id }
    )
  end
end
