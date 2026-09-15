class DataImport
  class ProductManager
    def initialize(account)
      @account = account
    end

    def process_rows(rows)
      records = []
      rejected_records = []

      # Group by product name
      grouped = rows.group_by { |row| row[:name].to_s.strip }

      grouped.each do |name, group_rows|
        if name.blank?
          # If name is blank, we can't create a product, reject all rows
          group_rows.each do |row|
            row['errors'] = I18n.t('errors.data_import.product.name_missing', default: "Name is missing")
            rejected_records << row
          end
          next
        end

        product, errors = build_product_with_variants(name, group_rows)
        
        if errors.empty? && product.save
          records << product
        else
          group_rows.each do |row|
            row['errors'] = errors.join(', ')
            rejected_records << row
          end
        end
      end

      [records, rejected_records]
    end

    private

    def build_product_with_variants(name, group_rows)
      first_row = group_rows.first
      
      product = @account.products.find_or_initialize_by(name: name)

      # Only update main attributes if it's a new product or we want to overwrite
      # Let's overwrite for simplicity, matching the CSV data.
      product.description = first_row[:description] if first_row[:description].present?
      product.price = first_row[:price] if first_row[:price].present?
      product.currency = first_row[:currency] || 'VND'
      product.status = first_row[:status] || 'draft'
      
      if first_row[:images].present?
        product.images = first_row[:images].split(',').map(&:strip)
      end

      meta = product.meta || {}
      meta['product_type'] = first_row[:product_type] if first_row[:product_type].present?
      meta['category'] = first_row[:category] if first_row[:category].present?
      meta['brand'] = first_row[:brand] if first_row[:brand].present?
      meta['style'] = first_row[:style] if first_row[:style].present?
      meta['attributes'] = first_row[:attributes] if first_row[:attributes].present?
      product.meta = meta

      errors = []

      unless product.valid?
        errors.concat(product.errors.full_messages)
        return [product, errors]
      end

      # Process variants
      group_rows.each do |row|
        next if row[:variant_name].blank? && row[:variant_sku].blank? && row[:variant_color].blank? && row[:variant_size].blank?
        
        # Determine variant identifier
        variant = if row[:variant_sku].present?
                    product.product_variants.find_or_initialize_by(sku: row[:variant_sku])
                  elsif row[:variant_name].present?
                    product.product_variants.find_or_initialize_by(name: row[:variant_name])
                  else
                    product.product_variants.build
                  end

        variant.name = row[:variant_name] if row[:variant_name].present?
        variant.barcode = row[:variant_barcode] if row[:variant_barcode].present?
        variant.price = row[:variant_price] if row[:variant_price].present?
        variant.weight = row[:variant_weight] if row[:variant_weight].present?

        variant_meta = variant.meta || {}
        variant_meta['color'] = row[:variant_color] if row[:variant_color].present?
        variant_meta['size'] = row[:variant_size] if row[:variant_size].present?
        variant_meta['length'] = row[:variant_length] if row[:variant_length].present?
        variant_meta['width'] = row[:variant_width] if row[:variant_width].present?
        variant_meta['height'] = row[:variant_height] if row[:variant_height].present?
        variant.meta = variant_meta

        unless variant.valid?
          errors.concat(variant.errors.full_messages)
        end
      end

      [product, errors]
    end
  end
end
