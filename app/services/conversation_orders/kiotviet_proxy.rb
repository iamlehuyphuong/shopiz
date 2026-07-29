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

  def fetch_orders(params = {})
    kiotviet_get('orders', params)
  end

  def update_order(order_id, payload)
    kiotviet_put("orders/#{order_id}", payload)
  end

  def delete_order(order_id, void_payment: true)
    kiotviet_delete("orders/#{order_id}?IsVoidPayment=#{void_payment}")
  end

  def fetch_customers(params = {})
    kiotviet_get('customers', params)
  end

  def fetch_customer(id)
    kiotviet_get("customers/#{id}")
  end

  def create_customer(payload)
    kiotviet_post('customers', payload)
  end

  def update_customer(id, payload)
    kiotviet_put("customers/#{id}", payload)
  end

  def fetch_products(page = 1)
    page_size = 50
    current_item = (page - 1) * page_size
    response = kiotviet_get("products?pageSize=#{page_size}&currentItem=#{current_item}&includeInventory=true")

    return [[], false] unless response && response['data'].present?

    # Group items by masterProductId (if present) or by their own id if standalone/master
    grouped_items = response['data'].group_by { |item| item['masterProductId'] || item['id'] }

    products_data = grouped_items.map do |master_id, items|
      # Find the actual master item if it is returned in this batch, otherwise fallback to the first item (a variant) to get common data.
      master_item = items.find { |i| i['id'] == master_id } || items.first

      {
        external_id: master_id.to_s,
        name: master_item['name'], # Name is usually the generic product name
        description: master_item['description'],
        price: master_item['basePrice'],
        currency: 'VND',
        sku: master_item['code'],
        barcode: master_item['barCode'],
        status: master_item['isActive'] ? 'active' : 'archived',
        images: master_item['images']&.map { |img| img['Image'] } || [],
        variants: items.reject { |i| i['id'] == master_id && i['hasVariants'] }.map do |item|
          # Map sellable items as variants. (The master item itself is excluded if it hasVariants = true).
          {
            external_id: item['id'].to_s,
            name: item['fullName'] || item['name'],
            price: item['basePrice'],
            sku: item['code'],
            barcode: item['barCode'],
            inventory_quantity: item.dig('inventories', 0, 'onHand') || 0,
            compare_at_price: nil
          }
        end
      }
    end

    total = response['total'].to_i
    has_more = (current_item + response['data'].length) < total

    [products_data, has_more]
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
