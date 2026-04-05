class Contacts::ContactInfoExtractorService
  # Regex patterns
  EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
  # Detects Vietnamese phone numbers starting with 0 or +84
  # Examples: 0901234567, +84901234567
  VN_PHONE_REGEX = /(?:\+84|0)([35789]\d{8})\b/

  def initialize(message)
    @message = message
    @account = message.account
    @contact = message.sender
  end

  def perform
    return unless @contact.is_a?(Contact)
    return if @message.private? # Don't extract from private notes

    extract_info(@message.content)
  end

  private

  def extract_info(content)
    return if content.blank?

    email = content.scan(EMAIL_REGEX).first
    phone = content.scan(VN_PHONE_REGEX).first&.first # The first capture group is the number without 0 or +84

    update_contact(email, phone)
  end

  def update_contact(email, phone)
    attributes_to_update = {}

    if email.present? && @contact.email.blank?
      attributes_to_update[:email] = email.downcase
    end

    if phone.present? && @contact.phone_number.blank?
      # Normalize to +84 for Vietnamese numbers
      attributes_to_update[:phone_number] = "+84#{phone}"
    end

    @contact.update(attributes_to_update) if attributes_to_update.any?
  end
end
