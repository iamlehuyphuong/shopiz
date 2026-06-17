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

    ::ContactInboxWithContactBuilder.new(
      source_id: data['uid'],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform
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
