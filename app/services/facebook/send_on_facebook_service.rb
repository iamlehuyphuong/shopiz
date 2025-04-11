class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  # Get channel class
  def channel_class
    Channel::FacebookPage
  end

  # Perform reply
  def perform_reply
    if message.content_type? && message.content_attributes?
      send_message_to_facebook fb_internative_message_params message
    elsif message.content.present?
      send_message_to_facebook fb_text_message_params
    end

    if message.attachments.present?
      message.attachments.each do |attachment|
        send_message_to_facebook fb_attachment_message_params(attachment)
      end
    end
  rescue Facebook::Messenger::FacebookError => e
    # TODO : handle specific errors or else page will get disconnected
    handle_facebook_error(e)
    message.update!(status: :failed, external_error: e.message)
  end

  # Send message to facebook
  def send_message_to_facebook(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    parsed_result = JSON.parse(result)
    if parsed_result['error'].present?
      message.update!(status: :failed, external_error: external_error(parsed_result))
      Rails.logger.info "Facebook::SendOnFacebookService: Error sending message to Facebook : Page - #{channel.page_id} : #{result}"
    end
    message.update!(source_id: parsed_result['message_id']) if parsed_result['message_id'].present?
  end

  # Facebook text message param
  def fb_text_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: { text: message.content },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  # External error
  def external_error(response)
    # https://developers.facebook.com/docs/graph-api/guides/error-handling/
    error_message = response['error']['message']
    error_code = response['error']['code']

    "#{error_code} - #{error_message}"
  end

  # Facebook attachment message params
  def fb_attachment_message_params(attachment)
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  # Facebook internative message
  def fb_internative_message_params(message)
    case message.content_type
    # 1. Options
    when 'input_select'
      fb_input_select_message_params message
    # 2. Form
    # when 'form'
    #   fb_form_message_params message
    # 3. Cards
    when 'cards'
      fb_card_message_params message
    end
  end

  # 1. Options: FB custom like option message
  def fb_input_select_message_params(message)
    # 1. Element
    items = message.content_attributes['items']
    quick_replies = items.map do |item|
      {
        content_type: 'text',
        title: item['title'],
        payload: item['value']
      }
    end
    # 2. Return
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.content,
        quick_replies: quick_replies
      },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  # 2. Form: FB form message params
  def fb_form_message_params(message)
    # 1. Fields
    fields = message.content_attributes['items'].map do |item|
      {
        label: item['label'],
        value: item['default'] || 'N/A'
      }
    end
    # 2. Return
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'structured_information',
            elements: [
              {
                title: message.content,
                fields: fields
              }
            ]
          }
        }
      },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  # 3. Facebook card message
  def fb_card_message_params(message)
    # 1. Element
    elements = message.content_attributes['items'].map do |item|
      {
        title: item['title'],
        image_url: item['media_url'],
        subtitle: item['description'],
        buttons: item['actions'].map do |action|
          if action['type'] == 'link'
            {
              type: 'web_url',
              title: action['text'],
              url: action['uri']
            }
          elsif action['type'] == 'postback'
            {
              type: 'postback',
              title: action['text'],
              payload: action['payload']
            }
          end
        end
      }
    end
    #  2. Return
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: elements
          }
        }
      },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  # Attachment type
  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  # Sent first outgoing message after 24 hours
  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
    conversation.messages.outgoing.where('id > ?', conversation.last_incoming_message.id).count == 1
  end

  # Handle facebook error
  def handle_facebook_error(exception)
    # Refer: https://github.com/jgorset/facebook-messenger/blob/64fe1f5cef4c1e3fca295b205037f64dfebdbcab/lib/facebook/messenger/error.rb
    return unless exception.to_s.include?('The session has been invalidated') || exception.to_s.include?('Error validating access token')

    channel.authorization_error!
  end
end
