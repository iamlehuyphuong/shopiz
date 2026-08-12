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
    Channel::FacebookPage.where(page_id: response.sender_id).each do |page|
      next if instagram_message_handled_by_dedicated_channel?(page)

      mb = Messages::Facebook::MessageBuilder.new(response, page.inbox, outgoing_echo: true)
      mb.perform
    end
  end

  def create_contact_message
    Channel::FacebookPage.where(page_id: response.recipient_id).each do |page|
      next if instagram_message_handled_by_dedicated_channel?(page)

      mb = Messages::Facebook::MessageBuilder.new(response, page.inbox)
      mb.perform
    end
  end

  # When a Facebook Page is linked to an Instagram Business Account AND a dedicated
  # Channel::Instagram exists for that same instagram_id, the Instagram webhook pipeline
  # (/webhooks/instagram) will handle the message. Skip it here to avoid duplicates
  # being routed to the Facebook inbox.
  def instagram_message_handled_by_dedicated_channel?(facebook_page)
    return false if facebook_page.instagram_id.blank?

    Channel::Instagram.exists?(instagram_id: facebook_page.instagram_id)
  end
end
