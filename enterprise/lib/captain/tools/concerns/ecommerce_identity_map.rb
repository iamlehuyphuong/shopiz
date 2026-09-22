module Captain::Tools::Concerns::EcommerceIdentityMap
  extend ActiveSupport::Concern

  def get_external_customer_id(contact, platform)
    return nil if contact.blank? || contact.additional_attributes.blank?

    contact.additional_attributes.dig('ecommerce_ids', platform.to_s)
  end

  def save_external_customer_id(contact, platform, customer_id)
    return if contact.blank? || customer_id.blank?

    # Initialize structure if it doesn't exist
    contact.additional_attributes ||= {}
    contact.additional_attributes['ecommerce_ids'] ||= {}

    # Update mapping
    contact.additional_attributes['ecommerce_ids'][platform.to_s] = customer_id.to_s

    # Save without triggering full validation to be safe and fast
    contact.save(validate: false)
  end
end
