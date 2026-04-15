# Sends one-off broadcast/promotion messages to Zalo OA followers
# Follows the same pattern as Facebook::OneoffCampaignService and ZaloPersonal::OneoffCampaignService
#
# Note: Zalo OA promotion messages can only be sent to followers of the OA
# Rate limits apply based on the OA's pricing plan
class Zalo::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" unless zalo_oa_campaign? && campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    campaign.completed!
    process_audience(extract_audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def client
    @client ||= channel.client
  end

  def zalo_oa_campaign?
    campaign.inbox.inbox_type == 'ZaloOa'
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
      # Only send to followers
      next unless contact.additional_attributes&.dig('zalo_is_follower')

      campaign.increment_metric!(:total_sent)
      begin
        process_contact(contact, contact_inbox)
      rescue StandardError => e
        campaign.increment_metric!(:failed)
        Rails.logger.error "Zalo::OneoffCampaignService: Error processing contact #{contact.id}: #{e.message}"
      end
    end
  end

  def process_contact(contact, contact_inbox)
    conversation = find_or_build_conversation(contact_inbox)
    content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)

    # Build promotion message payload
    body = build_promotion_body(contact_inbox.source_id, content, campaign.template_params)
    response = client.send_promotion_message(body)

    if response['error']&.zero?
      # Create message record for tracking
      conversation.messages.create!(
        account_id: campaign.account_id,
        inbox_id: campaign.inbox_id,
        message_type: :outgoing,
        content: content,
        source_id: response.dig('data', 'message_id')
      )
      campaign.increment_metric!(:delivered)
    else
      campaign.increment_metric!(:failed)
      Rails.logger.error "Zalo::OneoffCampaignService: Zalo API error for contact #{contact.id}: #{response['message']}"
    end
  end

  def build_promotion_body(user_id, content, template_params)
    body = {
      recipient: { user_id: user_id },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'promotion',
            language: 'VI',
            elements: [
              { type: 'banner', image_url: template_params&.dig('image_url') }.compact,
              { type: 'header', content: template_params&.dig('header') || '' },
              { type: 'text', content: content },
              build_button(template_params)
            ].compact
          }
        }
      }
    }

    # Remove empty elements
    body[:message][:attachment][:payload][:elements].reject! { |e| e[:content].blank? && e[:image_url].blank? && e[:title].blank? }
    body
  end

  def build_button(template_params)
    return nil if template_params.blank? || template_params['button_title'].blank?

    {
      type: 'button',
      title: template_params['button_title'],
      payload: { url: template_params['button_url'] }
    }
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
