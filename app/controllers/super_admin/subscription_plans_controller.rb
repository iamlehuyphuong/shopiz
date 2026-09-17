# frozen_string_literal: true
require 'csv'

class SuperAdmin::SubscriptionPlansController < SuperAdmin::ApplicationController
  def duplicate
    original = requested_resource
    @resource = original.dup
    @resource.sku = nil
    render :new, locals: { page: Administrate::Page::Form.new(dashboard, @resource) }
  end

  def export_xlsx
    respond_to do |format|
      format.xlsx do
        package = ::Axlsx::Package.new
        workbook = package.workbook
        workbook.add_worksheet(name: 'Subscription Plans') do |sheet|
          sheet.add_row ["sku", "subscription_tier_id", "tier_name_en", "price_amount", "currency", "duration_days", "visible", "is_default_for_new_account"]
          SubscriptionPlan.includes(:subscription_tier).find_each do |record|
            sheet.add_row [
              record.sku,
              record.subscription_tier_id,
              record.subscription_tier&.name_en,
              record.price_amount,
              record.currency,
              record.duration_days,
              record.visible,
              record.is_default_for_new_account
            ]
          end
        end
        send_data package.to_stream.read, filename: "subscription_packages_#{Date.today}.xlsx", type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      end
    end
  end

  def import_xlsx
    if params[:file].present?
      begin
        xlsx = Roo::Excelx.new(params[:file].path)
        headers = xlsx.row(1).map { |h| h.to_s.strip }
        
        return redirect_to super_admin_subscription_plans_path, flash: { error: "File trống" } if xlsx.last_row.nil? || xlsx.last_row < 2
        
        (2..xlsx.last_row).each do |i|
          row = Hash[[headers, xlsx.row(i)].transpose]
          plan = SubscriptionPlan.find_or_initialize_by(sku: row["sku"])
          
          if row["subscription_tier_id"].present?
            plan.subscription_tier_id = row["subscription_tier_id"]
          elsif row["tier_name_en"].present?
            tier = SubscriptionTier.find_by(name_en: row["tier_name_en"])
            plan.subscription_tier_id = tier.id if tier
          end
          
          plan.price_amount = row["price_amount"] if row["price_amount"].present?
          plan.currency = row["currency"] if row["currency"].present?
          plan.duration_days = row["duration_days"] if row["duration_days"].present?
          plan.visible = row["visible"] == "true" || row["visible"] == "1" if row["visible"].present?
          if row["is_default_for_new_account"].present?
            plan.is_default_for_new_account = row["is_default_for_new_account"] == "true" || row["is_default_for_new_account"] == "1"
          end
          plan.save!
        end
        flash[:notice] = "Nhập dữ liệu Packages thành công."
      rescue => e
        flash[:error] = "Lỗi khi nhập XLSX: #{e.message}"
      end
    else
      flash[:error] = "Vui lòng chọn tệp XLSX để tải lên."
    end
    redirect_to super_admin_subscription_plans_path
  end

  private

  def resource_params
    params.require(:subscription_plan).permit(
      :subscription_tier_id, :sku,
      :price_amount, :currency, :duration_days, :visible, :ai_included, :is_default_for_new_account
    )
  end
end
