class Contacts::ContactInfoExtractorService
  # Regex patterns
  EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
  # Detects Vietnamese phone numbers starting with 0 or +84
  # Examples: 0901234567, +84901234567, 0987 123 456, 0987.123.456
  VN_PHONE_REGEX = /(?:\+84|0)(?:[\s\-\.]?\d{2,4}){2,4}\b/
  CCCD_REGEX = /\b\d{12}\b/
  ADDRESS_KEYWORDS_REGEX = /(phường|xã|quận|huyện|đường|thành phố|tỉnh|cccd|cmnd|căn cước)/i

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

    phone = nil
    content.scan(VN_PHONE_REGEX).each do |match|
      digits_only = match.gsub(/[\s\-\.]/, '')
      match_data = digits_only.match(/^(?:\+84|0)([35789]\d{7,8})$/)
      if match_data
        phone = match_data[1]
        break
      end
    end

    # Keep the fast synchronous legacy contact update
    update_contact_fast(email, phone)

    trigger_ai_expansion(content, email, phone)
  end

  def trigger_ai_expansion(content, has_email, has_phone)
    has_cccd = content.match?(CCCD_REGEX)
    has_address = content.match?(ADDRESS_KEYWORDS_REGEX)

    # Nếu phát hiện bất kỳ dấu hiệu thông tin nào chưa có, hoặc có CCCD/Địa chỉ, ta gọi AI đọc lại ngữ cảnh.
    return unless has_email || has_phone || has_cccd || has_address
    return unless @account.feature_enabled?('captain_copilot') || @account.feature_enabled?('captain_assistant')

    CaptainContactAttributesJob.perform_later(@message.conversation_id)
  end

  def update_contact_fast(email, phone)
    attributes_to_update = {}

    attributes_to_update[:email] = email.downcase if email.present? && @contact.email.blank?

    if phone.present? && @contact.phone_number.blank?
      # Normalize to +84 for Vietnamese numbers
      attributes_to_update[:phone_number] = "+84#{phone}"
    end

    @contact.update(attributes_to_update) if attributes_to_update.any?
  end
end
