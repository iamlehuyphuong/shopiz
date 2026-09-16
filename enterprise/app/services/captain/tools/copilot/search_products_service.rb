class Captain::Tools::Copilot::SearchProductsService < Captain::Tools::BaseTool
  def self.name
    'search_products'
  end

  description 'Search for products natively in Shopiz by keyword, or list all products'
  param :query, type: :string, desc: 'Product name keyword to search for', required: false
  param :category_id, type: :integer, desc: 'Filter by category ID', required: false

  def execute(query: nil, **)
    keyword = extract_keyword_with_llm(query)
    
    active_platform = @assistant.account.active_ecommerce_platform.presence || 'shopiz'
    products = Product.where(account_id: @assistant.account_id, status: :active)

    if active_platform == 'shopiz'
      products = products.where("meta->>'source' IS NULL OR meta->>'source' = 'shopiz'")
    else
      products = products.where("meta->>'source' = ?", active_platform)
    end

    if keyword.present?
      search_term = "%#{keyword}%"
      products = products.left_joins(:product_variants).where(
        "products.name ILIKE :term OR products.description ILIKE :term OR products.sku ILIKE :term OR products.meta::text ILIKE :term OR product_variants.name ILIKE :term OR product_variants.sku ILIKE :term",
        term: search_term
      ).distinct
    end

    products = products.limit(15).includes(:product_variants)

    return "No products found matching '#{keyword.presence || 'all'}'. Please try another keyword." if products.blank?
    format_products(products)
  end

  def active?
    @user.present?
  end

  private

  def extract_keyword_with_llm(raw_query)
    return "" if raw_query.blank?

    prompt = "Extract the main product search keyword from this text. Return ONLY the keyword, nothing else. Text: #{raw_query}"
    res = RubyLLM.chat(provider: :openai, model: 'gpt-4o-mini', assume_model_exists: true).ask(prompt)
    res.text.strip
  rescue StandardError => e
    Rails.logger.error "[SearchProductsService] LLM extraction failed: #{e.message}"
    raw_query.to_s.strip
  end

  def format_products(products)
    results = ["## Product Search Results\n"]
    products.each do |product|
      results << "### #{product.name} (ID: #{product.id}, SKU: #{product.sku || 'N/A'})"
      results << "- Price: #{format_currency(product.price)}"
      results << "- Stock: #{product.inventory_quantity || 0}"
      
      variants = product.product_variants
      if variants.any?
        results << "- Variants:"
        variants.each do |v|
          results << "  - #{v.name} (SKU: #{v.sku || 'N/A'}) - Price: #{format_currency(v.price)} - Stock: #{v.inventory_quantity || 0}"
        end
      end
      results << ""
    end
    results.join("\n")
  end

  def format_currency(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: 'đ', format: '%n%u', precision: 0)
  end
end
