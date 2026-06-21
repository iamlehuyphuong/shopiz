class ZaloPersonal::ContactInboxBuilder
  def initialize(contact, inbox, phone_number)
    @contact = contact
    @inbox = inbox
    @phone_number = phone_number
  end

  def execute
    data = load_user_info
    return unless data

    contact_attributes = {
      name: data['display_name'],
      phone_number: @phone_number
    }

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: data['uid'],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    if contact_inbox.contact_id != @contact.id
      ContactMergeAction.new(
        account: @inbox.account,
        base_contact: @contact,
        mergee_contact: contact_inbox.contact
      ).perform

      contact_inbox.reload
    end

    contact_inbox
  end

  def load_user_info
    body = {
      phone: @phone_number,
      ownId: @inbox.channel.oa_id
    }

    res = HTTParty.post(
      info_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )
    return unless res['success']

    res['data']
  end

  def info_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/findUser"
  end
end
