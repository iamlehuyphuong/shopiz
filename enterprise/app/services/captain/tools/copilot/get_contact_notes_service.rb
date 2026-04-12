class Captain::Tools::Copilot::GetContactNotesService < Captain::Tools::BaseTool
  def self.name
    'get_contact_notes'
  end

  description 'Get internal notes for a contact to understand previous agent observations'
  param :contact_id, type: :number, desc: 'The ID of the contact to retrieve notes for', required: true

  def execute(contact_id:)
    contact = Contact.find_by(id: contact_id, account_id: @assistant.account_id)
    return 'Contact not found' if contact.nil?

    notes = contact.notes.latest.limit(50)
    return "No notes found for contact #{contact.name}" unless notes.exists?

    <<~RESPONSE
      Notes for contact: #{contact.name} (ID: #{contact.id})
      Total notes: #{contact.notes.count}#{contact.notes.count > 50 ? ' (showing latest 50)' : ''}
      #{notes.map { |n| format_note(n) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('contact_manage')
  end

  private

  def format_note(note)
    author = note.user&.name || 'System'
    <<~NOTE.strip
      [#{note.created_at.strftime('%Y-%m-%d %H:%M')}] by #{author}:
      #{note.content.truncate(500)}
    NOTE
  end
end
