class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    if %w[input_select cards marketing_optin].include?(message.content_type)
      send_message_to_facebook fb_internative_message_params(message)
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
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def send_message_to_facebook(delivery_params)
    parsed_result = deliver_message(delivery_params)
    return if parsed_result.nil?

    if parsed_result['error'].present?
      Messages::StatusUpdateService.new(message, 'failed', external_error(parsed_result)).perform
      Rails.logger.info "Facebook::SendOnFacebookService: Error sending message to Facebook : Page - #{channel.page_id} : #{parsed_result}"
      track_campaign_metric(:failed)
    else
      message.update!(source_id: parsed_result['message_id']) if parsed_result['message_id'].present?
      
      # Mark the message as a private reply so the frontend can style it appropriately.
      # Clear conversation-level comment_id hint after successful delivery to prevent
      # subsequent messages from also being sent as private replies.
      if message.content_attributes['target_comment_id'].present?
        message.update!(content_attributes: message.content_attributes.merge(is_private_reply: true).except('target_comment_id'))
        conversation.update!(additional_attributes: conversation.additional_attributes.except('comment_id'))
      end

      track_campaign_metric(:delivered)
    end
  end

  def deliver_message(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    JSON.parse(result)
  rescue JSON::ParserError
    Messages::StatusUpdateService.new(message, 'failed', 'Facebook was unable to process this request').perform
    Rails.logger.error "Facebook::SendOnFacebookService: Error parsing JSON response from Facebook : Page - #{channel.page_id} : #{result}"
    nil
  rescue Net::OpenTimeout
    Messages::StatusUpdateService.new(message, 'failed', 'Request timed out, please try again later').perform
    Rails.logger.error "Facebook::SendOnFacebookService: Timeout error sending message to Facebook : Page - #{channel.page_id}"
    nil
  end

  def fb_text_message_params
    base_params = {
      message: fb_text_message_payload
    }
    setup_recipient(base_params)
    base_params
  end

  def setup_recipient(base_params)
    if message.content_attributes['notification_messages_token'].present?
      base_params[:recipient] = { notification_messages_token: message.content_attributes['notification_messages_token'] }
    elsif message.content_attributes['target_comment_id'].present?
      base_params[:recipient] = { comment_id: message.content_attributes['target_comment_id'] }
    else
      base_params[:recipient] = { id: contact.get_source_id(inbox.id) }
      message_tag = message.content_attributes['message_tag']

      if message_tag.present?
        base_params[:messaging_type] = 'MESSAGE_TAG'
        base_params[:tag] = message_tag
      elsif under_24_hours?
        base_params[:messaging_type] = 'RESPONSE'
      else
        base_params[:messaging_type] = 'MESSAGE_TAG'
        base_params[:tag] = 'HUMAN_AGENT'
      end
    end
  end

  def under_24_hours?
    last_incoming_message_time > 24.hours.ago
  end

  def last_incoming_message_time
    conversation.last_incoming_message&.created_at || conversation.created_at
  end

  def fb_text_message_payload
    if message.content_type == 'input_select' && message.content_attributes['items'].any?
      {
        text: message.content,
        quick_replies: message.content_attributes['items'].map do |item|
          {
            content_type: 'text',
            payload: item['title'],
            title: item['title']
          }
        end
      }
    else
      { text: message.outgoing_content }
    end
  end

  def external_error(response)
    # https://developers.facebook.com/docs/graph-api/guides/error-handling/
    error_message = response['error']['message']
    error_code = response['error']['code']

    is_private_reply = message.content_attributes['target_comment_id'].present?

    if error_code == 100 && error_message.include?('HUMAN_AGENT')
      return I18n.t('errors.facebook.human_agent_error', error_code: error_code, error_message: error_message)
    end

    if error_code == 100 && error_message.include?('Only one message can be sent per comment')
      conversation.update!(additional_attributes: conversation.additional_attributes.except('comment_id')) if is_private_reply
      return I18n.t('errors.facebook.only_one_private_reply', error_code: error_code, error_message: error_message)
    end

    if error_code == 10 && error_message.include?('Private replies are only allowed')
      conversation.update!(additional_attributes: conversation.additional_attributes.except('comment_id')) if is_private_reply
      return I18n.t('errors.facebook.private_reply_timeout', error_code: error_code, error_message: error_message)
    end

    if error_code == 10901
      conversation.update!(additional_attributes: conversation.additional_attributes.except('comment_id')) if is_private_reply
    end

    "#{error_code} - #{error_message}"
  end

  def fb_attachment_message_params(attachment)
    base_params = {
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    }
    setup_recipient(base_params)
    base_params
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
    # 4. Marketing Optin
    when 'marketing_optin'
      fb_marketing_optin_message_params message
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
    base_params = {
      message: {
        text: message.content,
        quick_replies: quick_replies
      }
    }
    setup_recipient(base_params)
    base_params
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
    base_params = {
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
      }
    }
    setup_recipient(base_params)
    base_params
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
    base_params = {
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: elements
          }
        }
      }
    }
    setup_recipient(base_params)
    base_params
  end

  # 4. Marketing Optin
  def fb_marketing_optin_message_params(message)
    base_params = {
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'notification_messages',
            notification_messages_timezone: 'UTC',
            title: message.content,
            payload: message.content_attributes['topic'] || 'marketing'
          }
        }
      }
    }

    # Add image_url if provided
    if message.content_attributes['image_url'].present?
      base_params[:message][:attachment][:payload][:image_url] = message.content_attributes['image_url']
    end

    setup_recipient(base_params)
    base_params
  end

  def track_campaign_metric(status)
    campaign = conversation&.campaign
    return unless campaign

    campaign.increment_metric!(status)
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
    conversation.messages.outgoing.where('id > ?', conversation.last_incoming_message.id).count == 1
  end

  def handle_facebook_error(exception)
    # Refer: https://github.com/jgorset/facebook-messenger/blob/64fe1f5cef4c1e3fca295b205037f64dfebdbcab/lib/facebook/messenger/error.rb
    return unless exception.to_s.include?('The session has been invalidated') || exception.to_s.include?('Error validating access token')

    channel.authorization_error!
  end
end
