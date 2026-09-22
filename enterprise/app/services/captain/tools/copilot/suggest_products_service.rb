class Captain::Tools::Copilot::SuggestProductsService < Captain::Tools::BaseTool
  def self.name
    'suggest_products'
  end

  description 'Suggest products based on a query or context'
  param :query, type: :string, desc: 'Product name keyword or context to search for', required: false

  def execute(query: nil, **)
    keyword = extract_context_with_llm(query)

    active_platform = @assistant.account.active_ecommerce_platform.presence || 'shopiz'
    products = Product.where(account_id: @assistant.account_id, status: :active)

    products = if active_platform == 'shopiz'
                 products.where("meta->>'source' IS NULL OR meta->>'source' = 'shopiz'")
               else
                 products.where("meta->>'source' = ?", active_platform)
               end

    if keyword.present?
      search_term = "%#{keyword}%"
      products = products.left_joins(:product_variants).where(
        'products.name ILIKE :term OR products.description ILIKE :term OR products.sku ILIKE :term ' \
        'OR products.meta::text ILIKE :term OR product_variants.name ILIKE :term ' \
        'OR product_variants.sku ILIKE :term',
        term: search_term
      ).distinct
    end

    products = products.limit(10).includes(:product_variants)

    if products.blank?
      products = Product.where(account_id: @assistant.account_id, status: :active).limit(10).includes(:product_variants)
      if products.present?
        return "No products found matching context '#{keyword}'. Here are some available products to suggest:\n#{format_products(products)}"
      end

      return 'No products available to suggest.'
    end

    format_products(products)
  end

  def active?
    @user.present?
  end

  private

  def extract_context_with_llm(raw_query)
    return '' if raw_query.blank?

    prompt = <<~PROMPT
      You are an expert at extracting product search intent from a conversational context for a Vietnamese e-commerce system.
      Task: Extract the core product keywords or intent from the user's text to query the database.
      - Ignore generic chat words (e.g. "khách muốn mua", "giới thiệu", "tìm giúp").
      - Only output the exact corrected keywords. Do NOT include any other text, quotes, or explanations.

      User text: #{raw_query}
    PROMPT

    res = RubyLLM.chat(provider: :openai, model: 'gpt-4o-mini', assume_model_exists: true).ask(prompt)
    res.text.strip
  rescue StandardError => e
    Rails.logger.error "[SuggestProductsService] LLM extraction failed: #{e.message}"
    raw_query.to_s.strip
  end

  def format_products(products)
    results = ["## Product Suggestions\n"]
    products.each do |product|
      results << "### #{product.name} (ID: #{product.id}, SKU: #{product.sku || 'N/A'})"
      results << "- Price: #{format_currency(product.price)}"
      results << "- Stock: #{product.inventory_quantity || 0}"

      variants = product.product_variants
      if variants.any?
        results << '- Variants:'
        variants.each do |v|
          results << "  - #{v.name} (SKU: #{v.sku || 'N/A'}) - Price: #{format_currency(v.price)} - Stock: #{v.inventory_quantity || 0}"
        end
      end
      results << ''
    end
    results.join("\n")
  end

  def format_currency(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: 'đ', format: '%n%u', precision: 0)
  end
end
