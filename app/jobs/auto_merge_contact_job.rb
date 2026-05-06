class AutoMergeContactJob < ApplicationJob
  queue_as :default

  def perform(contact_id)
    base_contact = Contact.find_by(id: contact_id)
    return unless base_contact

    target_contact = find_target_contact(base_contact)
    return unless target_contact

    # The older contact (target_contact) becomes the base,
    # the newer contact (base_contact) becomes the mergee and is destroyed.
    ContactMergeAction.new(
      account: base_contact.account,
      base_contact: target_contact,
      mergee_contact: base_contact
    ).perform
  end

  private

  def find_target_contact(contact)
    if contact.phone_number.present?
      target = Contact.where(account_id: contact.account_id, phone_number: contact.phone_number)
                      .where.not(id: contact.id)
                      .order(created_at: :asc)
                      .first
      return target if target
    end

    if contact.email.present?
      target = Contact.where(account_id: contact.account_id, email: contact.email)
                      .where.not(id: contact.id)
                      .order(created_at: :asc)
                      .first
      return target if target
    end

    nil
  end
end
