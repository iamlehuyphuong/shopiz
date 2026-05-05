class Api::V1::Accounts::Sales::ProductsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_product, only: [:show, :update, :destroy]

  def index
    @products = current_account.products.order(created_at: :desc)
    render json: @products
  end

  def show
    render json: @product
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
    params.require(:product).permit(
      :name, :description, :price, :currency, :sku, :barcode, :status, :external_id, meta: {}
    )
  end
end
