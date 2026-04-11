# frozen_string_literal: true
require 'csv'

class SuperAdmin::SubscriptionPlansController < SuperAdmin::ApplicationController
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
          csv << ["sku", "subscription_tier_id", "tier_name_en", "price_amount", "currency", "duration_days", "visible"]
          SubscriptionPlan.includes(:subscription_tier).find_each do |record|
            csv << [
              record.sku,
              record.subscription_tier_id,
              record.subscription_tier&.name_en,
              record.price_amount,
              record.currency,
              record.duration_days,
              record.visible
            ]
          end
        end
        send_data csv_data, filename: "subscription_packages_#{Date.today}.csv"
      end
    end
  end

  def import_csv
    if params[:file].present?
      begin
        CSV.foreach(params[:file].path, headers: true) do |row|
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
          plan.save!
        end
        flash[:notice] = "Nhập dữ liệu Packages thành công."
      rescue => e
        flash[:error] = "Lỗi khi nhập CSV: #{e.message}"
      end
    else
      flash[:error] = "Vui lòng chọn tệp CSV để tải lên."
    end
    redirect_to super_admin_subscription_plans_path
  end

  private

  def resource_params
    params.require(:subscription_plan).permit(
      :subscription_tier_id, :sku,
      :price_amount, :currency, :duration_days, :visible
    )
  end
end
