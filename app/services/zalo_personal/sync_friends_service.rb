class ZaloPersonal::SyncFriendsService
  def initialize(inbox)
    @inbox = inbox
  end

  def perform
    return unless @inbox.channel.is_a?(Channel::ZaloPersonal)

    friends = load_all_friends
    return if friends.blank?

    friends.each do |friend_data|
      create_or_update_contact(friend_data)
    end
  end

  private

  def load_all_friends
    body = { ownId: @inbox.channel.oa_id }

    res = HTTParty.post(
      sync_url,
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )

    return unless res['success']

    res['data']
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal SyncFriendsService error for inbox #{@inbox.id}: #{e.message}"
    nil
  end

  def create_or_update_contact(friend_data)
    phone_number = friend_data['phoneNumber'].presence
    phone_number = "+#{phone_number}" if phone_number.present? && !phone_number.start_with?('+')

    additional_attributes = {
      zalo_friend_inbox_ids: friend_data['isFr'] ? [@inbox.id] : [],
      source_id: friend_data['userId']
    }
    additional_attributes[:description] = friend_data['status'] if friend_data['status'].present?

    contact_attributes = {
      name: friend_data['zaloName'].presence || friend_data['displayName'].presence || 'Zalo User',
      phone_number: phone_number,
      avatar_url: friend_data['avatar'].presence,
      additional_attributes: additional_attributes
    }.compact

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: friend_data['userId'],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    return unless contact_inbox

    contact = contact_inbox.contact

    # Update other attributes like gender and birthday, similar to base_service.rb
    update_params = {}
    gender_value = friend_data['gender']
    update_params[:gender_id] = gender_value if gender_value.present? && Contact.gender_ids.value?(gender_value.to_i)

    if friend_data['sdob'].present?
      begin
        # Assuming Zalo sdob is DD/MM/YYYY or similar
        update_params[:birthday] = Date.parse(friend_data['sdob'])
      rescue StandardError
        # ignore parse error
      end
    end

    # BaseService also updates attributes directly in case ContactInboxBuilder reused an existing contact
    attrs = contact.additional_attributes || {}

    unless friend_data['isFr'].nil?
      inbox_ids = Array(attrs['zalo_friend_inbox_ids'] || attrs[:zalo_friend_inbox_ids] || [])
      if friend_data['isFr']
        inbox_ids |= [@inbox.id]
      else
        inbox_ids -= [@inbox.id]
      end
      attrs[:zalo_friend_inbox_ids] = inbox_ids.uniq.compact
    end

    attrs[:description] = friend_data['status'] if friend_data['status'].present?

    update_params[:additional_attributes] = attrs

    contact.update!(update_params) if update_params.present?
  end

  def sync_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getallfriends"
  end
end
