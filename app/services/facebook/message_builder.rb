class Facebook::MessageBuilder < Messages::Messenger::MessageBuilder
  # rubocop:disable Lint/MissingSuper
  def initialize(conversation, page_id, messaging)
    @conversation = conversation
    @page_id = page_id
    @messaging = messaging
  end
  # rubocop:enable Lint/MissingSuper

  def perform
    @message = @conversation.messages.create!(message_params)

    if @messaging.dig('attachments', 'data')
      attachments = graph.get_connection(@messaging['id'], 'attachments')
      attachments.each do |attachment|
        attachment['type'] = file_type(attachment['mime_type'])
        process_attachment(attachment)
      end
    end

    @message
  end

  private

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: @messaging['message'],
      source_id: @messaging['id'],
      sender: sender,
      created_at: created_time,
      loaded_from_history: true
    }
  end

  def message_type
    incomming_message? ? :incoming : :outgoing
  end

  def sender
    incomming_message? ? @conversation.contact_inbox.contact : nil
  end

  def incomming_message?
    from_id != @page_id
  end

  def from_id
    @messaging.dig('from', 'id')
  end

  def created_time
    Time.iso8601(@messaging['created_time'])
  rescue StandardError
    Time.zone.now
  end

  def file_type_params(attachment)
    {
      external_url: attachment['file_url'] || attachment.dig('image_data', 'url'),
      remote_file_url: attachment['file_url'] || attachment.dig('image_data', 'url')
    }
  end

  def location_params(attachment)
    lat = attachment.dig('payload', 'coordinates', 'lat')
    long = attachment.dig('payload', 'coordinates', 'long')
    {
      external_url: attachment['url'],
      coordinates_lat: lat,
      coordinates_long: long,
      fallback_title: attachment['title']
    }
  end

  def fallback_params(attachment)
    {
      fallback_title: attachment['title'],
      external_url: attachment['url']
    }
  end

  def graph
    @graph ||= Koala::Facebook::API.new(@conversation.inbox.channel.page_access_token)
  end
end
