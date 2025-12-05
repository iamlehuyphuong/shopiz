class ZaloPersonal::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign!
    process_audience(extract_audience_labels)
    campaign.completed!
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def validate_campaign!
    validate_campaign_type!
    validate_campaign_status!
    validate_feature_flag!
  end

  def validate_campaign_type!
    raise "Invalid campaign #{campaign.id}" unless zalopersonal_campaign? && campaign.one_off?
  end

  def zalopersonal_campaign?
    campaign.inbox.inbox_type == 'ZaloPersonal'
  end

  def validate_campaign_status!
    raise 'Completed Campaign' if campaign.completed?
  end

  def validate_feature_flag!
    raise 'Channel Zalo Personal feature not enabled' unless campaign.account.feature_enabled?(:channel_zalopersonal)
  end

  def extract_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end

  def process_audience(audience_labels)
    contacts = Contact.joins(contact_inboxes: :inbox)
                      .tagged_with(audience_labels, any: true)
                      .where(account_id: campaign.account_id)
                      .where(inboxes: { channel_type: 'Channel::ZaloPersonal' })
                      .select('contacts.*, contact_inboxes.source_id AS zalo_source_id')
                      .distinct
    Rails.logger.info "Processing #{contacts.size} contacts for campaign #{campaign.id}"

    contacts.each do |contact|
      content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)
      send_message(to: contact.zalo_source_id, content: content)
    end
  end

  def send_message(to:, content:)
    channel.send_text_message(to, content)
  rescue StandardError => e
    Rails.logger.error("Zalo Personal #{campaign.id}] Failed to send to #{to}: #{e.message}")
  end
end
