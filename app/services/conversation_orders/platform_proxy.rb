# Base proxy class for all platform-specific order integrations.
# Subclasses only need to implement #create_order and #fetch_order.
class ConversationOrders::PlatformProxy
  attr_reader :account

  def initialize(account)
    @account = account
    # Copilot client concerns (e.g., KiotvietClient) look up credentials via
    # @assistant.account_id. We provide a lightweight compatibility shim so
    # those concerns work in both Copilot and PlatformProxy contexts.
    @assistant = Struct.new(:account_id).new(account.id)
  end

  def create_order(_payload)
    raise NotImplementedError, "#{self.class}#create_order not implemented"
  end

  def update_order(_order_id, _payload)
    raise NotImplementedError, "#{self.class}#update_order not implemented"
  end

  def fetch_order(_order_id)
    raise NotImplementedError, "#{self.class}#fetch_order not implemented"
  end

  def fetch_products(_page = 1)
    raise NotImplementedError, "#{self.class}#fetch_products not implemented"
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

  # Extract raw status from a fetch response (platform-specific)
  def extract_raw_status(result)
    result['status'] || result['financial_status'] || result['statusCode']
  end

  # Extract total amount from a fetch response (platform-specific)
  def extract_total(result)
    result['totalPayment'] || result['total_price'] || result['total'] ||
      result.dig('payment', 'total_amount')
  end

  def platform_name
    self.class.name.demodulize.sub('Proxy', '')
  end
end
