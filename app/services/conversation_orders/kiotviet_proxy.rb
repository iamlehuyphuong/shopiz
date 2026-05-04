# Proxy for KiotViet Order API.
# Uses the shared KiotvietClient concern for auth and HTTP calls.
class ConversationOrders::KiotvietProxy < ConversationOrders::PlatformProxy
  include Captain::Tools::Concerns::KiotvietClient

  def create_order(payload)
    kiotviet_post('orders', payload)
  end

  def fetch_order(order_id)
    kiotviet_get("orders/#{order_id}")
  end

  def map_status(raw_status)
    # KiotViet Order: 1=Temporary, 2=Processing, 3=Completed, 4=Cancelled
    case raw_status
    when 1 then :draft
    when 2 then :processing
    when 3 then :delivered
    when 4 then :cancelled
    end
  end

  def extract_order_id(result)
    result&.dig('id')&.to_s
  end

  def extract_raw_status(result)
    result['statusCode']
  end

  def extract_total(result)
    result['totalPayment']
  end
end
