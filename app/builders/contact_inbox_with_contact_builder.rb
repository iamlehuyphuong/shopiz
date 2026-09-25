# This Builder will create a contact and contact inbox with specified attributes.
# If an existing identified contact exisits, it will be returned.
# for contact inbox logic it uses the contact inbox builder

class ContactInboxWithContactBuilder
  pattr_initialize [:inbox!, :contact_attributes!, :source_id, :hmac_verified]

  def perform
    find_or_create_contact_and_contact_inbox
  # in case of race conditions where contact is created by another thread
  # we will try to find the contact and create a contact inbox
  rescue ActiveRecord::RecordNotUnique
    find_or_create_contact_and_contact_inbox
  end

  def find_or_create_contact_and_contact_inbox
    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id) if source_id.present?

    if @contact_inbox
      @contact = @contact_inbox.contact
      update_contact_avatar(@contact) unless @contact.avatar.attached?

      is_default_name = [
        'John Doe', Channel::Instagram::DEFAULT_USER_NAME
      ].include?(@contact.name) || @contact.name.to_s.match?(/^(Khách hàng|Customer) - /)

      is_new_name_present_and_different = contact_attributes[:name].present? && contact_attributes[:name] != @contact.name

      is_new_name_not_default = !contact_attributes[:name].to_s.match?(/^(Khách hàng|Customer) - /) &&
                                contact_attributes[:name] != Channel::Instagram::DEFAULT_USER_NAME

      @contact.update(name: contact_attributes[:name]) if is_default_name && is_new_name_present_and_different && is_new_name_not_default

      return @contact_inbox
    end

    ActiveRecord::Base.transaction(requires_new: true) do
      build_contact_with_contact_inbox
    end
    update_contact_avatar(@contact) unless @contact.avatar.attached?
    @contact_inbox
  end

  private

  def build_contact_with_contact_inbox
    @contact = find_contact || create_contact
    append_source_to_existing_contact if @contact.persisted? && !@contact.previously_new_record?
    @contact_inbox = create_contact_inbox
  end

  def account
    @account ||= inbox.account
  end

  def create_contact_inbox
    ContactInboxBuilder.new(
      contact: @contact,
      inbox: @inbox,
      source_id: @source_id,
      hmac_verified: hmac_verified
    ).perform
  end

  def update_contact_avatar(contact)
    ::Avatar::AvatarFromUrlJob.perform_later(contact, contact_attributes[:avatar_url]) if contact_attributes[:avatar_url]
  end

  def create_contact
    attrs = contact_attributes[:additional_attributes] || {}
    attrs['sources'] = ["#{inbox.channel_type} | #{inbox.name}"]

    account.contacts.create!(
      name: contact_attributes[:name] || ::Haikunator.haikunate(1000),
      phone_number: contact_attributes[:phone_number],
      email: contact_attributes[:email],
      identifier: contact_attributes[:identifier],
      additional_attributes: attrs,
      custom_attributes: contact_attributes[:custom_attributes]
    )
  end

  def append_source_to_existing_contact
    new_source = "#{inbox.channel_type} | #{inbox.name}"
    current_sources = @contact.additional_attributes&.dig('sources') || []
    return if current_sources.include?(new_source)

    @contact.update!(
      additional_attributes: (@contact.additional_attributes || {}).merge(
        'sources' => (current_sources + [new_source]).uniq
      )
    )
  end

  def find_contact
    contact = find_contact_by_identifier(contact_attributes[:identifier])
    contact ||= find_contact_by_email(contact_attributes[:email])
    contact ||= find_contact_by_phone_number(contact_attributes[:phone_number])

    contact
  end

  def instagram_channel?
    inbox.channel_type == 'Channel::Instagram'
  end

  def find_contact_by_identifier(identifier)
    return if identifier.blank?

    account.contacts.find_by(identifier: identifier)
  end

  def find_contact_by_email(email)
    return if email.blank?

    account.contacts.from_email(email)
  end

  def find_contact_by_phone_number(phone_number)
    return if phone_number.blank?

    account.contacts.find_by(phone_number: phone_number)
  end
end
