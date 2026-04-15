# frozen_string_literal: true
require 'csv'

class SuperAdmin::SubscriptionTiersController < SuperAdmin::ApplicationController
  def duplicate
    original = requested_resource
    @resource = original.dup
    render :new, locals: { page: Administrate::Page::Form.new(dashboard, @resource) }
  end

  def export_csv
    respond_to do |format|
      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          csv << ["id", "name_en", "name_vi", "description_en", "description_vi", "limits", "features", "visible", "is_free"]
          SubscriptionTier.find_each do |record|
            csv << [
              record.id,
              record.name_en,
              record.name_vi,
              record.description_en,
              record.description_vi,
              record.limits.to_json,
              record.features.to_json,
              record.visible,
              record.is_free
            ]
          end
        end
        send_data csv_data, filename: "subscription_tiers_#{Date.today}.csv"
      end
    end
  end

  def import_csv
    if params[:file].present?
      begin
        CSV.foreach(params[:file].path, headers: true) do |row|
          tier = SubscriptionTier.find_or_initialize_by(name_en: row["name_en"])
          tier.name_vi = row["name_vi"] if row["name_vi"].present?
          tier.description_en = row["description_en"]
          tier.description_vi = row["description_vi"]
          tier.limits = row["limits"].present? ? JSON.parse(row["limits"]) : {}
          tier.features = row["features"].present? ? JSON.parse(row["features"]) : {}
          tier.visible = row["visible"] == "true" || row["visible"] == "1" if row["visible"].present?
          tier.is_free = row["is_free"] == "true" || row["is_free"] == "1" if row["is_free"].present?
          tier.save!
        end
        flash[:notice] = "Nhập dữ liệu Tiers thành công."
      rescue => e
        flash[:error] = "Lỗi khi nhập CSV: #{e.message}"
      end
    else
      flash[:error] = "Vui lòng chọn tệp CSV để tải lên."
    end
    redirect_to super_admin_subscription_tiers_path
  end

  private

  def resource_params
    params.require(:subscription_tier).permit(
      :name_en, :name_vi, :description_en, :description_vi,
      :visible, :is_free,
      limits: {}, features: {}
    )
  end
end
