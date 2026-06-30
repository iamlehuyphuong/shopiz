class Contacts::ContactInfoExtractorService
  # Regex patterns
  EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
  # Detects Vietnamese phone numbers starting with 0 or +84
  # Examples: 0901234567, +84901234567, 0987 123 456, 0987.123.456
  VN_PHONE_REGEX = /(?:\+84|0)(?:[\s\-\.]?\d{2,4}){2,4}\b/

  ADDRESS_KEYWORDS = 'xã|phường|tỉnh|thành phố|quận|huyện|toà nhà|khu phố|lô|' \
                     'ngõ|ngách|hẻm|đường|tổ|ấp|thôn|bản|khóm|x\.|p\.|t\.|tp\.|q\.|h\.'.freeze
  ADDRESS_KEYWORDS_REGEX = /(#{ADDRESS_KEYWORDS})/i

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

    address_data = extract_address(content)

    update_contact_info(email, phone, address_data)
  end

  def extract_address(content)
    # Split message into lines or sentences
    lines = content.split(/[\n\.]/)

    lines.each do |line|
      line = line.strip
      # Check reasonable length to avoid picking up single words or massive paragraphs
      next if line.length < 10 || line.length > 150

      if line.match?(ADDRESS_KEYWORDS_REGEX)
        parsed = VietnamAddressParser.parse(line)
        return parsed if parsed
      end
    end

    nil
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
  def update_contact_info(email, phone, address_data)
    attributes_to_update = {}

    attributes_to_update[:email] = email.downcase if email.present? && @contact.email.blank?

    if phone.present? && @contact.phone_number.blank?
      # Normalize to +84 for Vietnamese numbers
      attributes_to_update[:phone_number] = "+84#{phone}"
    end

    if address_data.present?
      attributes_to_update[:location] = address_data[:location] if address_data[:location].present? && @contact.location.blank?
      attributes_to_update[:country_code] = address_data[:country_code] if address_data[:country_code].present? && @contact.country_code.blank?

      if address_data[:city].present? && @contact.additional_attributes['city'].blank?
        attributes_to_update[:additional_attributes] = @contact.additional_attributes.merge('city' => address_data[:city])
      end
    end

    @contact.update(attributes_to_update) if attributes_to_update.any?
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
end
