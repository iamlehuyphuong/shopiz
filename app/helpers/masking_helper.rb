module MaskingHelper
  def self.mask_email(email)
    return email if email.blank?

    parts = email.split('@')
    return email if parts.length != 2

    username, domain = parts

    masked_username = if username.length <= 4
                        "#{username[0]}***#{username[-1]}"
                      else
                        "#{username[0..1]}***#{username[-2..]}"
                      end

    "#{masked_username}@#{domain}"
  end

  def self.mask_phone(phone)
    return phone if phone.blank?

    return phone if phone.length <= 6

    first_part = phone[0..2]
    last_part = phone[-3..]

    "#{first_part}***#{last_part}"
  end
end
