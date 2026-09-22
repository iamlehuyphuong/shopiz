class Captain::Tools::GetProductDetailsTool < Captain::Tools::BasePublicTool
  description 'Retrieve detailed information and variants of a specific product using its ID or SKU'

  param :product_id, type: 'string', desc: 'The internal ID of the product', required: false
  param :sku, type: 'string', desc: 'The SKU of the product', required: false

  def perform(tool_context, product_id: nil, sku: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    return 'Either product_id or sku must be provided' if product_id.blank? && sku.blank?

    # Retrieve from local DB directly as products are synced to Shopiz
    log_tool_usage('get_product_details', { conversation_id: conversation.id, product_id: product_id, sku: sku })

    product = find_product(product_id, sku)
    return 'Product not found with provided ID or SKU' unless product

    format_product_details(product)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to retrieve product details'
  end

  private

  def permissions
    %w[conversation_manage]
  end

  def find_product(product_id, sku)
    query = account_scoped(Product).includes(:product_variants)

    if product_id.present?
      query.find_by(id: product_id)
    else
      query.find_by(sku: sku)
    end
  end

  def format_product_details(product)
    details = {
      id: product.id,
      name: product.name,
      description: product.description,
      sku: product.sku,
      price: product.price,
      status: product.status,
      variants: format_variants(product.product_variants)
    }

    "Product Details:\n#{details.to_json}"
  end

  def format_variants(variants)
    variants.map do |variant|
      {
        id: variant.id,
        name: variant.name,
        sku: variant.sku,
        price: variant.price,
        quantity: variant.quantity,
        options: variant.options # Hash of option_name => option_value
      }.compact
    end
  end
end
