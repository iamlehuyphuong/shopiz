class Captain::Tools::UpdateContactTool < Captain::Tools::BasePublicTool
  description 'Update contact profile information such as name, email, phone number, gender, biography or custom attributes'
  param :name, type: 'string', desc: 'The new name for the contact', required: false
  param :email, type: 'string', desc: 'The new email address for the contact', required: false
  param :phone_number, type: 'string', desc: 'The new phone number in E.164 format (e.g. +84901234567)', required: false
  param :gender, type: 'string', desc: 'Gender of the contact: "male" or "female"', required: false
  param :biography, type: 'string', desc: 'Short biography or description of the contact', required: false
  param :custom_attributes, type: 'string', desc: 'JSON string of custom attributes to merge (e.g. {"order_id": "123", "vip": true})', required: false

  def perform(tool_context, name: nil, email: nil, phone_number: nil, gender: nil, biography: nil, custom_attributes: nil)
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact

    updates = build_updates(contact, name: name, email: email, phone_number: phone_number,
                                     gender: gender, biography: biography, custom_attributes: custom_attributes)
    return 'At least one field to update is required' if updates.empty?

    contact.update!(updates)

    log_tool_usage('update_contact', { contact_id: contact.id, fields: updates.keys })

    "Contact '#{contact.name}' (ID: #{contact.id}) updated: #{updates.keys.join(', ')}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update contact: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def build_updates(contact, name:, email:, phone_number:, gender:, biography:, custom_attributes:)
    updates = {}
    updates[:name] = name.strip if name.present?
    updates[:email] = email.strip.downcase if email.present?
    updates[:phone_number] = phone_number.strip if phone_number.present?

    if gender.present?
      normalized = gender.strip.downcase
      updates[:gender_id] = normalized if Contact.gender_ids.key?(normalized)
    end

    if biography.present?
      additional = contact.additional_attributes || {}
      updates[:additional_attributes] = additional.merge('description' => biography.strip)
    end

    if custom_attributes.present?
      parsed = custom_attributes.is_a?(String) ? JSON.parse(custom_attributes) : custom_attributes
      updates[:custom_attributes] = (contact.custom_attributes || {}).merge(parsed)
    end

    updates
  end

  def permissions
    %w[contact_manage]
  end
end
