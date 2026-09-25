class Sales::ProductsSyncService
  def initialize(account:, platform:)
    @account = account
    @platform = platform
  end

  def perform
    Rails.logger.info("ProductsSyncService: Starting sync for account #{@account.id}, platform: #{@platform}")
    proxy = build_proxy
    unless proxy
      Rails.logger.error("ProductsSyncService: Failed to build proxy for #{@platform}")
      return
    end

    page = 1
    total_upserted = 0
    loop do
      Rails.logger.info("ProductsSyncService: Fetching page #{page} from #{@platform} proxy")
      products_data, has_more = proxy.fetch_products(page)

      Rails.logger.info("ProductsSyncService: Fetched #{products_data&.size || 0} products on page #{page}. has_more: #{has_more}")
      break if products_data.blank?

      errors = upsert_products(products_data)
      Rails.logger.info("ProductsSyncService: Upserted #{products_data.size} products. Errors: #{errors.size}")
      total_upserted += (products_data.size - errors.size)

      break unless has_more

      page += 1
    end
    Rails.logger.info("ProductsSyncService: Completed sync for account #{@account.id}, total upserted: #{total_upserted}")
  rescue StandardError => e
    Rails.logger.error("Failed to sync products from #{@platform} for account #{@account.id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end

  private

  def build_proxy
    proxy_class = ConversationOrders::PlatformRegistry.proxy_for(@platform)

    unless proxy_class
      Rails.logger.error("Proxy class not found for platform #{@platform}")
      return nil
    end

    proxy_class.new(@account)
  end

  def upsert_products(products_data)
    errors = []
    products_data.each do |data|
      # Skip if external_id is not provided
      next if data[:external_id].blank?

      begin
        product = @account.products.find_or_initialize_by(external_id: data[:external_id])

        product.assign_attributes(
          name: data[:name],
          description: data[:description],
          price: data[:price],
          currency: data[:currency] || 'VND',
          sku: data[:sku],
          barcode: data[:barcode],
          status: data[:status] || 'active',
          meta: (product.meta || {}).merge('source' => @platform, 'images' => data[:images] || [])
        )

        # Handle variants if any
        if data[:variants].present? && data[:variants].is_a?(Array)
          data[:variants].each do |v_data|
            variant = product.product_variants.find_or_initialize_by(external_id: v_data[:external_id])
            variant.assign_attributes(
              account_id: @account.id,
              name: v_data[:name],
              price: v_data[:price],
              sku: v_data[:sku],
              barcode: v_data[:barcode],
              inventory_quantity: v_data[:inventory_quantity],
              compare_at_price: v_data[:compare_at_price],
              meta: (variant.meta || {}).merge('source' => @platform)
            )
          end
        end

        product.save!
      rescue StandardError => e
        error_msg = "Failed to upsert product #{data[:external_id]}: #{e.message}"
        Rails.logger.error(error_msg)
        errors << error_msg
      end
    end

    # Could optionally return or record errors for Partial Success notification
    errors
  end
end
