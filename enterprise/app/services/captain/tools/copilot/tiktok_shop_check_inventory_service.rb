class Captain::Tools::Copilot::TiktokShopCheckInventoryService < Captain::Tools::BaseTool
  include Captain::Tools::Concerns::TiktokShopClient

  def self.name
    'tiktok_shop_check_inventory'
  end

  description 'Check inventory level for a specific product or SKU on TikTok Shop.'
  param :product_id, type: :string, desc: 'TikTok Shop product ID'

  def execute(**args)
    arguments = args.stringify_keys
    return 'TikTok Shop integration is not connected.' unless tiktok_shop_active?

    product_id = arguments['product_id']
    return 'Please provide a product_id.' if product_id.blank?

    product = fetch_product_inventory(product_id)
    return "Product ID #{product_id} not found." if product.nil?

    format_inventory(product)
  end

  def active?
    @user.present? && tiktok_shop_active?
  end

  private

  def fetch_product_inventory(product_id)
    result = tiktok_shop_get("/product/202309/products/#{product_id}")
    result&.dig('data')
  end

  def format_inventory(product)
    lines = ["📦 **Inventory Status for: #{product['title']}** (ID: #{product['id']})\n"]

    total_stock = 0
    skus = product['skus'] || []

    if skus.empty?
      lines << 'No SKUs found for this product.'
      return lines.join("\n")
    end

    skus.each do |sku|
      stock = sku.dig('inventory', 'quantity').to_i
      total_stock += stock

      sku_name = sku['seller_sku'].presence || sku['id']
      lines << "- SKU: #{sku_name} | Stock: **#{stock}**"
    end

    lines << "\n**Total Stock:** #{total_stock}"
    lines.join("\n")
  end
end
