# == Schema Information
#
# Table name: zalo_message_templates
#
#  id               :bigint           not null, primary key
#  template_name    :string           not null
#  template_type    :integer          not null, default(0)
#  template_content :jsonb            not null, default({})
#  language         :string           default("VI")
#  status           :integer          not null, default(0)
#  account_id       :bigint           not null
#  channel_id       :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_zalo_message_templates_on_account_id  (account_id)
#  index_zalo_message_templates_on_channel_id  (channel_id)
#  idx_zalo_templates_unique                   (account_id,template_name,channel_id) UNIQUE
#

class ZaloMessageTemplate < ApplicationRecord
  belongs_to :account
  belongs_to :channel, class_name: 'Channel::ZaloOa'

  validates :template_name, presence: true
  validates :template_name, uniqueness: { scope: [:account_id, :channel_id] }
  validates :template_content, presence: true

  enum template_type: {
    transaction_order: 0,      # Thông báo đơn hàng
    transaction_payment: 1,    # Thông báo thanh toán
    transaction_shipping: 2,   # Thông báo vận chuyển
    transaction_otp: 3,        # Xác thực OTP
    transaction_reward: 4,     # Thông báo tích điểm/voucher
    promotion: 5               # Tin truyền thông / marketing
  }

  enum status: {
    draft: 0,
    active: 1,
    disabled: 2
  }

  scope :active_templates, -> { where(status: :active) }
  scope :by_type, ->(type) { where(template_type: type) }

  # Build the Zalo API payload from template content
  # Template content structure:
  # {
  #   "elements": [
  #     { "type": "header", "content": "Thông báo đơn hàng" },
  #     { "type": "text", "content": "Đơn hàng {{order_id}} đã được xác nhận" },
  #     { "type": "table", "content": [{ "key": "Mã đơn", "value": "{{order_id}}" }] },
  #     { "type": "button", "title": "Xem chi tiết", "payload": { "url": "{{order_url}}" } }
  #   ]
  # }
  def build_payload(user_id, variables = {})
    rendered_elements = render_elements(variables)
    {
      recipient: { user_id: user_id },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: zalo_template_type,
            language: language,
            elements: rendered_elements
          }
        }
      }
    }
  end

  private

  def zalo_template_type
    if template_type.start_with?('transaction_')
      template_type.sub('transaction_', 'transaction_')
    else
      'promotion'
    end
  end

  def render_elements(variables)
    elements = template_content['elements'] || []
    elements.map do |element|
      rendered = element.deep_dup
      replace_variables(rendered, variables)
      rendered
    end
  end

  def replace_variables(element, variables)
    if element.is_a?(Hash)
      element.each do |key, value|
        if value.is_a?(String)
          variables.each do |var_name, var_value|
            element[key] = element[key].gsub("{{#{var_name}}}", var_value.to_s)
          end
        elsif value.is_a?(Array) || value.is_a?(Hash)
          replace_variables(value, variables)
        end
      end
    elsif element.is_a?(Array)
      element.each { |item| replace_variables(item, variables) }
    end
  end
end
