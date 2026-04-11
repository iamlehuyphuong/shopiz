# frozen_string_literal: true
require 'csv'

class SuperAdmin::AddonPackagesController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  def duplicate
    original = requested_resource
    @resource = original.dup
    @resource.sku = nil
    render :new, locals: { page: Administrate::Page::Form.new(dashboard, @resource) }
  end

  def export_csv
    respond_to do |format|
      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          csv << ["sku", "name", "addon_type", "quantity", "price_amount", "currency", "duration_days", "visible"]
          AddonPackage.find_each do |record|
            csv << [
              record.sku,
              record.name,
              record.addon_type,
              record.quantity,
              record.price_amount,
              record.currency,
              record.duration_days,
              record.visible
            ]
          end
        end
        send_data csv_data, filename: "addon_packages_#{Date.today}.csv"
      end
    end
  end

  def import_csv
    if params[:file].present?
      begin
        CSV.foreach(params[:file].path, headers: true) do |row|
          addon = AddonPackage.find_or_initialize_by(sku: row["sku"])
          addon.name = row["name"] if row["name"].present?
          addon.addon_type = row["addon_type"] if row["addon_type"].present?
          addon.quantity = row["quantity"] if row["quantity"].present?
          addon.price_amount = row["price_amount"] if row["price_amount"].present?
          addon.currency = row["currency"] if row["currency"].present?
          addon.duration_days = row["duration_days"].present? ? row["duration_days"] : nil
          addon.visible = row["visible"] == "true" || row["visible"] == "1" if row["visible"].present?
          addon.save!
        end
        flash[:notice] = "Nhập dữ liệu Addon thành công."
      rescue => e
        flash[:error] = "Lỗi khi nhập CSV: #{e.message}"
      end
    else
      flash[:error] = "Vui lòng chọn tệp CSV để tải lên."
    end
    redirect_to super_admin_addon_packages_path
  end

  private

  def resource_params
    params.require(:addon_package).permit(
      :sku, :name, :name_en, :name_vi, :addon_type, :quantity, :price_amount, :currency, :duration_days, :visible
    )
  end
end
