class Api::V1::Accounts::Conversations::ProductsController < Api::V1::Accounts::Conversations::BaseController
  def index
    platform = params[:source] || @conversation.inbox.sales_config&.dig('platform') || 'shopiz'

    # Check if there are ANY products for this platform in the DB.
    has_synced_data = if platform == 'shopiz' || platform == 'all'
                        true
                      else
                        Current.account.products.where("meta->>'source' = ?", platform).exists?
                      end

    products = fetch_synced_products(platform, params[:q].to_s.strip, params[:page].to_i)
    
    render json: { 
      products: products,
      has_synced_data: has_synced_data
    }
  end

  private

  def fetch_synced_products(platform, query, page)
    products = Current.account.products.active.order(created_at: :desc)

    # Filter by source in metadata if it's not 'shopiz' or 'all'
    if platform != 'shopiz' && platform != 'all'
      products = products.where("meta->>'source' = ?", platform)
    elsif platform == 'shopiz'
      # Shopiz native products either have no source or source is shopiz
      products = products.where("meta->>'source' IS NULL OR meta->>'source' = 'shopiz'")
    end

    if query.present?
      search_term = "%#{query}%"
      products = products.where('name ILIKE ? OR sku ILIKE ?', search_term, search_term)
    end

    products = products.page(page + 1).per(20)

    products.map do |p|
      thumbnail = nil
      if p.respond_to?(:images) && p.images.is_a?(Array)
        thumbnail = p.images.first
      elsif p.meta.is_a?(Hash) && p.meta['images'].is_a?(Array)
        thumbnail = p.meta['images'].first
      end

      source = p.meta&.dig('source') || 'shopiz'

      {
        id: p.id.to_s,
        name: p.name,
        price: p.price.to_f,
        thumbnail: thumbnail,
        source: source,
        in_stock: p.inventory_quantity.to_i.positive? || p.meta&.dig('in_stock') || true
      }
    end
  end
end
