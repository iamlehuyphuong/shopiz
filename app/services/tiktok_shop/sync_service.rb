class TiktokShop::SyncService
  MAX_CONVERSATION_PAGES = 10
  MAX_MESSAGE_PAGES = 5
  PAGE_SIZE = 20
  RATE_LIMIT_DELAY = 0.5 # seconds between API calls

  def initialize(channel)
    @channel = channel
    @inbox = channel.inbox
    @client = channel.client
  end

  def perform
    sync_conversations
  end

  private

  def sync_conversations
    paginate(MAX_CONVERSATION_PAGES) do |page_token|
      response = fetch_with_retry { @client.get_conversations(build_params(page_token)) }
      break unless response&.dig('code')&.zero?

      conversations = response.dig('data', 'conversations') || []
      break if conversations.empty?

      conversations.each do |conv_data|
        sync_messages(conv_data['conversation_id'])
        sleep(RATE_LIMIT_DELAY)
      end

      response.dig('data', 'next_page_token')
    end
  end

  def sync_messages(conversation_id)
    all_messages = []

    paginate(MAX_MESSAGE_PAGES) do |page_token|
      response = fetch_with_retry { @client.get_messages(conversation_id, build_params(page_token)) }
      break unless response&.dig('code')&.zero?

      messages = response.dig('data', 'messages') || []
      all_messages.concat(messages)

      response.dig('data', 'next_page_token')
    end

    # Process oldest first to maintain correct sequence
    all_messages.reverse_each { |msg_data| process_message(conversation_id, msg_data) }
  end

  def build_params(page_token)
    params = { page_size: PAGE_SIZE }
    params[:page_token] = page_token if page_token.present?
    params
  end

  def paginate(max_pages)
    page_token = nil
    max_pages.times do
      page_token = yield(page_token)
      break if page_token.blank?

      sleep(RATE_LIMIT_DELAY)
    end
  end

  def process_message(conversation_id, msg_data)
    payload = {
      shop_id: @channel.shop_id,
      data: msg_data.merge(conversation_id: conversation_id)
    }.with_indifferent_access

    ::TiktokShop::IncomingMessageService.new(inbox: @inbox, params: payload).perform
  rescue StandardError => e
    Rails.logger.error "TiktokShop::SyncService error: #{e.message}"
  end

  def fetch_with_retry
    response = yield
    if response['code'] == Channel::TiktokShop::INVALID_ACCESS_TOKEN_CODE
      @channel.refresh_access_token
      response = yield
    end
    response
  rescue StandardError => e
    Rails.logger.error "TiktokShop::SyncService fetch error: #{e.message}"
    nil
  end
end
