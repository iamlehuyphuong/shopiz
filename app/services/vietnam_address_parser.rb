class VietnamAddressParser
  # 34 provinces and cities according to the new administrative restructuring
  PROVINCES = [
    'An Giang', 'Bắc Ninh', 'Cà Mau', 'Cao Bằng', 'Cần Thơ',
    'Đắk Lắk', 'Đà Nẵng', 'Điện Biên', 'Đồng Nai', 'Đồng Tháp',
    'Gia Lai', 'Hà Nội', 'Hà Tĩnh', 'Hải Phòng', 'Hồ Chí Minh',
    'Huế', 'Hưng Yên', 'Khánh Hòa', 'Lai Châu', 'Lâm Đồng',
    'Lạng Sơn', 'Lào Cai', 'Nghệ An', 'Ninh Bình', 'Phú Thọ',
    'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị', 'Sơn La', 'Tây Ninh',
    'Thái Nguyên', 'Thanh Hóa', 'Tuyên Quang', 'Vĩnh Long'
  ].freeze

  # Mapping old provinces or common abbreviations to standard names
  PROVINCE_ALIASES = {
    # Merged provinces
    'Hà Giang' => 'Tuyên Quang',
    'Yên Bái' => 'Lào Cai',
    'Bắc Kạn' => 'Thái Nguyên',
    'Vĩnh Phúc' => 'Phú Thọ',
    'Hòa Bình' => 'Phú Thọ',
    'Bắc Giang' => 'Bắc Ninh',
    'Thái Bình' => 'Hưng Yên',
    'Hải Dương' => 'Hải Phòng',
    'Hà Nam' => 'Ninh Bình',
    'Nam Định' => 'Ninh Bình',
    'Quảng Bình' => 'Quảng Trị',
    'Quảng Nam' => 'Đà Nẵng',
    'Kon Tum' => 'Quảng Ngãi',
    'Bình Định' => 'Gia Lai',
    'Ninh Thuận' => 'Khánh Hòa',
    'Đắk Nông' => 'Lâm Đồng',
    'Bình Thuận' => 'Lâm Đồng',
    'Phú Yên' => 'Đắk Lắk',
    'Bà Rịa - Vũng Tàu' => 'Hồ Chí Minh',
    'Bình Dương' => 'Hồ Chí Minh',
    'Bình Phước' => 'Đồng Nai',
    'Long An' => 'Tây Ninh',
    'Sóc Trăng' => 'Cần Thơ',
    'Hậu Giang' => 'Cần Thơ',
    'Bến Tre' => 'Vĩnh Long',
    'Trà Vinh' => 'Vĩnh Long',
    'Tiền Giang' => 'Đồng Tháp',
    'Bạc Liêu' => 'Cà Mau',
    'Kiên Giang' => 'An Giang',
    'Thừa Thiên Huế' => 'Huế',

    # Very old provinces and common aliases
    'Hà Tây' => 'Hà Nội',
    'Sài Gòn' => 'Hồ Chí Minh',
    'SG' => 'Hồ Chí Minh',
    'HCM' => 'Hồ Chí Minh',
    'TP HCM' => 'Hồ Chí Minh',
    'TP.HCM' => 'Hồ Chí Minh',
    'TP. Hồ Chí Minh' => 'Hồ Chí Minh',
    'HN' => 'Hà Nội'
  }.freeze

  class << self
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def parse(address_string)
      return nil if address_string.blank?

      address_string = address_string.strip
      found_city = nil
      matched_keyword = nil

      # Check standard provinces first (case insensitive)
      PROVINCES.each do |province|
        next unless address_string.match?(/\b#{Regexp.escape(province)}\b/i)

        found_city = province
        matched_keyword = province
        break
      end

      # If not found, check aliases
      if found_city.nil?
        PROVINCE_ALIASES.each do |alias_name, standard_name|
          next unless address_string.match?(/\b#{Regexp.escape(alias_name)}\b/i)

          found_city = standard_name
          matched_keyword = alias_name
          break
        end
      end

      location = address_string
      if found_city.present?
        # Remove the matched city/province from the address string to get the 'location'
        # e.g., "Số 10 Ngọc Lâm, Hà Nội" -> "Số 10 Ngọc Lâm, "
        # Also strip trailing commas and spaces
        location = address_string.sub(/(tỉnh|thành phố|tp\.)?\s*#{Regexp.escape(matched_keyword)}\b/i, '').gsub(/,\s*$/, '').strip
      end

      {
        city: found_city,
        location: location,
        country_code: 'VN'
      }
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength
  end
end
