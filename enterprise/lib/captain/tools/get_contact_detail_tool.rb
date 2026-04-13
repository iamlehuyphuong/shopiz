class Captain::Tools::GetContactDetailTool < Captain::Tools::BasePublicTool
  description 'Get detailed information about the current contact including name, email, phone, gender, biography, custom attributes and conversation history summary'

  def perform(tool_context)
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact

    log_tool_usage('get_contact_details', { contact_id: contact.id })

    format_contact_details(contact)
  end

  private

  def format_contact_details(contact)
    details = []
    details << "Name: #{contact.name}" if contact.name.present?
    details << "Email: #{contact.email}" if contact.email.present?
    details << "Phone: #{contact.phone_number}" if contact.phone_number.present?
    details << "Gender: #{contact.gender_id}" if contact.gender_id.present?
    details << "Type: #{contact.contact_type}" if contact.contact_type.present?
    details << "Location: #{contact.location}" if contact.location.present?
    details << "Birthday: #{contact.birthday.strftime('%Y-%m-%d')}" if contact.birthday.present?

    biography = contact.additional_attributes&.dig('description')
    details << "Biography: #{biography}" if biography.present?

    details << "Created: #{contact.created_at.strftime('%Y-%m-%d')}"
    details << "Last activity: #{contact.last_activity_at&.strftime('%Y-%m-%d %H:%M')}"

    if contact.custom_attributes.present? && contact.custom_attributes.any?
      details << "Custom attributes: #{contact.custom_attributes.map { |k, v| "#{k}: #{v}" }.join(', ')}"
    end

    conversation_count = contact.conversations.where(account_id: @assistant.account_id).count
    details << "Total conversations: #{conversation_count}"

    details.join("\n")
  end
end
