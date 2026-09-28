class Account::ProductsExportJob < ApplicationJob
  queue_as :low

  def perform(account_id, user_id, _column_names = nil, filter_params = nil)
    @account = Account.find(account_id)
    @account_user = @account.users.find(user_id)
    @filter_params = filter_params || {}

    generate_csv
    send_mail
  end

  private

  def generate_csv
    headers = default_headers

    csv_data = CSV.generate do |csv|
      csv << headers

      products.each do |product|
        base_data = [
          product.name,
          product.description,
          product.price,
          product.currency,
          product.sku,
          product.barcode,
          product.images&.join(','),
          product.status,
          product.meta&.dig('product_type'),
          product.meta&.dig('category'),
          product.meta&.dig('brand'),
          product.meta&.dig('style'),
          product.meta&.dig('attributes')
        ]

        if product.product_variants.any?
          product.product_variants.each do |variant|
            row = base_data + [
              variant.name,
              variant.sku,
              variant.barcode,
              variant.price,
              variant.weight,
              variant.meta&.dig('color'),
              variant.meta&.dig('size'),
              variant.meta&.dig('length'),
              variant.meta&.dig('width'),
              variant.meta&.dig('height')
            ]
            csv << row
          end
        else
          # No variants, just main product
          row = base_data + Array.new(10)
          csv << row
        end
      end
    end

    attach_export_file(csv_data)
  end

  def products
    # We can filter here if needed, for now export all or by source
    scope = @account.products.includes(:product_variants)
    if @filter_params[:source].present? && @filter_params[:source] != 'all'
      scope = if @filter_params[:source] == 'shopiz'
                scope.where("meta->>'source' IS NULL OR meta->>'source' = 'shopiz'")
              else
                scope.where("meta->>'source' = ?", @filter_params[:source])
              end
    end
    scope
  end

  def attach_export_file(csv_data)
    return if csv_data.blank?

    @account.products_export.attach(
      io: StringIO.new(csv_data),
      filename: "#{@account.name}_#{@account.id}_products.csv",
      content_type: 'text/csv'
    )
  end

  def send_mail
    return if @account.custom_email_config.blank? || @account.custom_email_config['smtp_address'].blank?

    file_url = account_product_export_url
    mailer = AdministratorNotifications::AccountNotificationMailer.with(account: @account)
    mailer.product_export_complete(file_url, @account_user.email)&.deliver_later
  end

  def account_product_export_url
    Rails.application.routes.url_helpers.rails_blob_url(@account.products_export)
  end

  def default_headers
    %w[
      name description price currency sku barcode images status product_type category brand style attributes
      variant_name variant_sku variant_barcode variant_price variant_weight
      variant_color variant_size variant_length variant_width variant_height
    ]
  end
end
