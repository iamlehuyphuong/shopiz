# Base proxy class for all platform-specific order integrations.
# Subclasses only need to implement #create_order and #fetch_order.
class ConversationOrders::PlatformProxy
  def initialize(account)
    @account = account
    # KiotvietClient concern looks up via @assistant.account_id
    @assistant = OpenStruct.new(account_id: account.id)
  end

  def create_order(_payload)
    raise NotImplementedError, "#{self.class}#create_order not implemented"
  end

  def fetch_order(_order_id)
    raise NotImplementedError, "#{self.class}#fetch_order not implemented"
  end

  # Map platform-specific status to ConversationOrder enum.
  # Returns nil if unmappable (caller should default).
  def map_status(_raw_status)
    nil
  end

  # Extract external order ID from a create response
  def extract_order_id(result)
    result&.dig('id')&.to_s
  end

  # Extract error message from a failed response
  def extract_error(result)
    result&.dig('errorMessage') || result&.dig('message') || result&.dig('errors')&.first || "API call failed for #{platform_name}"
  end

  def platform_name
    self.class.name.demodulize.sub('Proxy', '')
  end
end
