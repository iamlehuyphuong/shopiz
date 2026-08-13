# frozen_string_literal: true

class Integrations::Facebook::MessageCreator
  attr_reader :response

  def initialize(response)
    @response = response
  end

  def perform
    # begin
    if agent_message_via_echo?
      create_agent_message
    else
      create_contact_message
    end
    # rescue => e
    # ChatwootExceptionTracker.new(e).capture_exception
    # end
  end

  private

  def agent_message_via_echo?
    # TODO : check and remove send_from_chatwoot_app if not working
    response.echo? && !response.sent_from_chatwoot_app?
    # this means that it is an agent message from page, but not sent from chatwoot.
    # User can send from fb page directly on mobile / web messenger, so this case should be handled as agent message
  end

  def create_agent_message
    get_facebook_pages(response.sender_id).each do |page|
      backfill_instagram_id(page) if page.instagram_id.blank?

      mb = Messages::Facebook::MessageBuilder.new(response, page.inbox, outgoing_echo: true)
      mb.perform
    end
  end

  def create_contact_message
    get_facebook_pages(response.recipient_id).each do |page|
      backfill_instagram_id(page) if page.instagram_id.blank?

      mb = Messages::Facebook::MessageBuilder.new(response, page.inbox)
      mb.perform
    end
  end

  def get_facebook_pages(id)
    # Search by page_id (Facebook messages)
    Channel::FacebookPage.where(page_id: id).to_a
  end

  def backfill_instagram_id(facebook_page)
    fb_object = Koala::Facebook::API.new(facebook_page.page_access_token)
    res = fb_object.get_connections('me', '', { fields: 'instagram_business_account' })
    if res['instagram_business_account'].present?
      facebook_page.update!(instagram_id: res['instagram_business_account']['id'])
    end
  rescue StandardError => e
    Rails.logger.warn("[MessageCreator] Failed to backfill instagram_id for FacebookPage #{facebook_page.id}: #{e.message}")
  end

end
