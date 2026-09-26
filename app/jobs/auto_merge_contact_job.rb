class AutoMergeContactJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotUnique do |_job, error|
    Rails.logger.info("[AutoMerge] Discarded due to uniqueness conflict: #{error.message}")
  end

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
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[AutoMerge] Skipped merge for Contact##{contact_id}: #{e.message}")
  end

  private

  def find_target_contact(contact)
    targets = []

    if contact.phone_number.present?
      target_by_phone = Contact.where(account_id: contact.account_id, phone_number: contact.phone_number)
                               .where.not(id: contact.id)
                               .order(created_at: :asc)
                               .first
      targets << target_by_phone if target_by_phone
    end

    if contact.email.present?
      target_by_email = Contact.where(account_id: contact.account_id, email: contact.email)
                               .where.not(id: contact.id)
                               .order(created_at: :asc)
                               .first
      targets << target_by_email if target_by_email
    end

    targets.compact.uniq.min_by(&:created_at)
  end
end
