# Public tool: Suggest upsell/cross-sell products from the local product catalog.
# Products are pre-synced from the active e-commerce platform.
class Captain::Tools::SuggestProductsTool < Captain::Tools::BasePublicTool
  description 'Suggest upsell and cross-sell products based on the current product selection and conversation context'

  param :product_identifier, type: 'string', desc: 'Product ID or code to base suggestions on', required: true
  param :context, type: 'string', desc: 'What the customer is looking for', required: false

  def perform(tool_context, product_identifier:, context: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    # Process via local DB directly as products are synced to Shopiz
    log_tool_usage('suggest_products', { product_identifier: product_identifier, context: context })
    suggest_local_products(conversation, product_identifier, context)
  end

  private

  def permissions
    %w[conversation_manage]
  end

  def suggest_local_products(conversation, product_identifier, context)
    account = conversation.account
    base_product = account.products.find_by(id: product_identifier) || account.products.find_by(sku: product_identifier)

    query = account.products.where(status: :active)
    
    active_platform = account.active_ecommerce_platform.presence || 'shopiz'
    query = if active_platform == 'shopiz'
              query.where("meta->>'source' IS NULL OR meta->>'source' = 'shopiz'")
            else
              query.where("meta->>'source' = ?", active_platform)
            end
            
    query = query.where.not(id: base_product.id) if base_product

    # Extract keywords from context and build an OR search
    search_results = []
    if context.present?
      keywords = context.to_s.split(/\s+/).reject { |w| w.length < 3 }.first(5)
      if keywords.any?
        # Ensure SQL injection safety
        conditions = keywords.map do |kw|
          sanitized_kw = ActiveRecord::Base.connection.quote_string(kw)
          "name ILIKE '%#{sanitized_kw}%' OR description ILIKE '%#{sanitized_kw}%'"
        end.join(' OR ')

        search_results = query.where(conditions).limit(5).to_a
      end
    end

    # Backfill with random products if not enough results
    if search_results.size < 10
      remaining = 10 - search_results.size
      existing_ids = search_results.map(&:id)
      random_query = query
      random_query = random_query.where.not(id: existing_ids) if existing_ids.any?
      random_products = random_query.order('RANDOM()').limit(remaining).to_a

      search_results.concat(random_products)
    end

    return 'No products available to suggest.' if search_results.empty?

    format_local_suggestions(base_product, search_results, context)
  end

  def format_local_suggestions(base_product, products, context)
    lines = []
    lines << "Base Product: #{base_product.name} (ID: #{base_product.id}) — #{base_product.price}" if base_product
    lines << "Customer context: #{context}\n" if context.present?

    lines << 'Please select the best 2-3 products from the list below to suggest to the customer based on their context:'

    products.each do |p|
      stock = p.inventory_quantity.to_i
      lines << "  • #{p.name} (ID: #{p.id}) — Price: #{p.price} | Stock: #{stock}"
      lines << "    Description: #{p.description&.truncate(100) || 'N/A'}"
    end

    lines.join("\n")
  end
end
