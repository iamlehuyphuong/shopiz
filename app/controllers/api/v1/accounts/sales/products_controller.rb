class Api::V1::Accounts::Sales::ProductsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_product, only: [:show, :update, :destroy]

  def index
    @products = current_account.products.order(created_at: :desc)

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @products = @products.where('name ILIKE ? OR sku ILIKE ?', search_term, search_term)
    end

    @products = @products.page(params[:page]).per(params[:per_page] || 15)

    render json: {
      payload: @products,
      meta: {
        current_page: @products.current_page,
        total_pages: @products.total_pages,
        total_count: @products.total_count
      }
    }
  end

  def show
    render json: @product
  end

  def sync
    Sales::ProductsSyncJob.perform_later(current_account.id, params[:platform])
    head :accepted
  end

  def create
    @product = current_account.products.new(product_params)
    if @product.save
      render json: @product
    else
      render json: { error: @product.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      render json: @product
    else
      render json: { error: @product.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    head :no_content
  end

  private

  def check_authorization
    # temporary using administrator policy or custom policy
    authorize current_account, :sales_manage?
  end

  def set_product
    @product = current_account.products.find(params[:id])
  end

  def product_params
    permitted = params.require(:product).permit(
      :name, :description, :price, :currency, :sku, :barcode, :status, :external_id,
      images: [],
      product_variants_attributes: [
        :id, :account_id, :name, :sku, :barcode, :price, :compare_at_price, 
        :inventory_quantity, :weight, :_destroy, meta: {}
      ]
    )
    if params.dig(:product, :meta).present?
      meta_params = params.dig(:product, :meta)
      permitted[:meta] = meta_params.respond_to?(:permit!) ? meta_params.permit! : meta_params
    end

    # Inject account_id into nested product_variants_attributes
    if permitted[:product_variants_attributes].present?
      permitted[:product_variants_attributes].each do |variant_attrs|
        variant_attrs[:account_id] = current_account.id
      end
    end

    permitted
  end
end
