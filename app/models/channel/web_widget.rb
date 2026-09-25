# == Schema Information
#
# Table name: channel_web_widgets
#
#  id                    :integer          not null, primary key
#  allowed_domains       :text             default("")
#  feature_flags         :integer          default(7), not null
#  hmac_mandatory        :boolean          default(FALSE)
#  hmac_token            :string
#  pre_chat_form_enabled :boolean          default(FALSE)
#  pre_chat_form_options :jsonb
#  reply_time            :integer          default("in_a_few_minutes")
#  website_token         :string
#  website_url           :string
#  welcome_tagline       :string
#  welcome_title         :string
#  widget_color          :string           default("#E06720")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer
#
# Indexes
#
#  index_channel_web_widgets_on_hmac_token     (hmac_token) UNIQUE
#  index_channel_web_widgets_on_website_token  (website_token) UNIQUE
#

class Channel::WebWidget < ApplicationRecord
  include Channelable
  include FlagShihTzu

  self.table_name = 'channel_web_widgets'
  EDITABLE_ATTRS = [:website_url, :widget_color, :welcome_title, :welcome_tagline, :reply_time, :pre_chat_form_enabled,
                    :hmac_mandatory, :allowed_domains, :bubble_avatar, :close_bubble_avatar,
                    { pre_chat_form_options: [:pre_chat_message, :require_email,
                                              { pre_chat_fields:
                                                [:field_type, :label, :placeholder, :name, :enabled, :type, :enabled, :required,
                                                 :locale, { values: [] }, :regex_pattern, :regex_cue] }] },
                    { selected_feature_flags: [] }].freeze

  before_validation :validate_pre_chat_options
  validates :website_url, presence: true
  validates :widget_color, presence: true

  has_one_attached :bubble_avatar
  has_one_attached :close_bubble_avatar

  has_secure_token :website_token
  has_secure_token :hmac_token

  has_flags 1 => :attachments,
            2 => :emoji_picker,
            3 => :end_conversation,
            4 => :use_inbox_avatar_for_bot,
            5 => :allow_mobile_webview,
            :column => 'feature_flags',
            :check_for_column => false

  enum reply_time: { in_a_few_minutes: 0, in_a_few_hours: 1, in_a_day: 2 }

  def bubble_avatar_url
    return '' unless bubble_avatar.attached?

    host = ENV.fetch('FRONTEND_URL', nil)

    if bubble_avatar.content_type == 'image/svg+xml' || bubble_avatar.filename.to_s.downcase.end_with?('.svg')
      return Rails.application.routes.url_helpers.url_for(bubble_avatar, host: host) if host.present?

      return Rails.application.routes.url_helpers.url_for(bubble_avatar)

    end

    if bubble_avatar.representable?
      begin
        return Rails.application.routes.url_helpers.url_for(bubble_avatar.representation(resize_to_fill: [250, nil]), host: host) if host.present?

        return Rails.application.routes.url_helpers.url_for(bubble_avatar.representation(resize_to_fill: [250, nil]))

      rescue StandardError
        # fallback to direct url if representation fails
      end
    end

    if host.present?
      Rails.application.routes.url_helpers.url_for(bubble_avatar, host: host)
    else
      Rails.application.routes.url_helpers.url_for(bubble_avatar)
    end
  end

  def close_bubble_avatar_url
    return '' unless close_bubble_avatar.attached?

    host = ENV.fetch('FRONTEND_URL', nil)

    if close_bubble_avatar.content_type == 'image/svg+xml' || close_bubble_avatar.filename.to_s.downcase.end_with?('.svg')
      return Rails.application.routes.url_helpers.url_for(close_bubble_avatar, host: host) if host.present?

      return Rails.application.routes.url_helpers.url_for(close_bubble_avatar)

    end

    if close_bubble_avatar.representable?
      begin
        if host.present?
          return Rails.application.routes.url_helpers.url_for(close_bubble_avatar.representation(resize_to_fill: [250, nil]), host: host)
        end

        return Rails.application.routes.url_helpers.url_for(close_bubble_avatar.representation(resize_to_fill: [250, nil]))

      rescue StandardError
        # fallback to direct url if representation fails
      end
    end

    if host.present?
      Rails.application.routes.url_helpers.url_for(close_bubble_avatar, host: host)
    else
      Rails.application.routes.url_helpers.url_for(close_bubble_avatar)
    end
  end

  def name
    'Website'
  end

  def web_widget_script
    "
    <script>
      (function(d,t) {
        var BASE_URL=\"#{ENV.fetch('FRONTEND_URL', '')}\";
        var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
        g.src=BASE_URL+\"/packs/js/sdk.js\";
        g.async = true;
        s.parentNode.insertBefore(g,s);
        g.onload=function(){
          window.shopizSDK.run({
            websiteToken: '#{website_token}',
            baseUrl: BASE_URL
          })
        }
      })(document,\"script\");
    </script>
    "
  end

  def validate_pre_chat_options
    return if pre_chat_form_options.with_indifferent_access['pre_chat_fields'].present?

    self.pre_chat_form_options = {
      pre_chat_message: 'Share your queries or comments here.',
      pre_chat_fields: [
        {
          'field_type': 'standard', 'label': 'Email Id', 'name': 'emailAddress', 'type': 'email', 'required': true, 'enabled': false
        },
        {
          'field_type': 'standard', 'label': 'Full name', 'name': 'fullName', 'type': 'text', 'required': false, 'enabled': false
        },
        {
          'field_type': 'standard', 'label': 'Phone number', 'name': 'phoneNumber', 'type': 'text', 'required': false, 'enabled': false
        }
      ]
    }
  end

  def create_contact_inbox(additional_attributes = {})
    ::ContactInboxWithContactBuilder.new({
                                           inbox: inbox,
                                           contact_attributes: { additional_attributes: additional_attributes }
                                         }).perform
  end
end
