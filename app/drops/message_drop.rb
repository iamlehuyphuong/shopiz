class MessageDrop < BaseDrop
  include MessageFormatHelper

  def sender_display_name
    @obj.sender.try(:available_name)
  end

  def text_content
    content = @obj.try(:content) || ''
    render_message_content(transform_user_mention_content(content))
  end

  def content
    @obj.try(:content) || ''
  end

  def html_content
    if @obj.content_attributes.present? && @obj.content_attributes.with_indifferent_access.dig(:email, :html_content, :reply).present?
      @obj.content_attributes.with_indifferent_access.dig(:email, :html_content, :reply)
    else
      @obj.try(:outgoing_content)
    end
  end

  def attachments
    return unless @obj.attachments.present?

    @obj.attachments.map do |attachment|
      file_url = begin
        attachment.file_url
      rescue ArgumentError => e
        if e.message.include?('Missing host')
          Rails.application.routes.url_helpers.url_for(attachment.file.tap { |f| f.class.default_url_options[:host] = 'localhost:3000' })
        else
          ''
        end
      end

      {
        'file_url' => file_url,
        'filename' => attachment.file.filename.to_s
      }
    end
  end

  def message_type
    @obj.try(:message_type) || 'outgoing'
  end

  def incoming?
    message_type == 'incoming'
  end
end
