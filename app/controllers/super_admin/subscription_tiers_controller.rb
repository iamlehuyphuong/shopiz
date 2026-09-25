# frozen_string_literal: true

require 'csv'

class SuperAdmin::SubscriptionTiersController < SuperAdmin::ApplicationController
  def duplicate
    original = requested_resource
    @resource = original.dup
    render :new, locals: { page: Administrate::Page::Form.new(dashboard, @resource) }
  end

  def export_xlsx
    respond_to do |format|
      format.xlsx do
        package = ::Axlsx::Package.new
        workbook = package.workbook
        workbook.add_worksheet(name: 'Subscription Tiers') do |sheet|
          sheet.add_row %w[id name_en name_vi description_en description_vi limits features visible is_free]
          SubscriptionTier.find_each do |record|
            sheet.add_row [
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
        send_data package.to_stream.read, filename: "subscription_tiers_#{Date.today}.xlsx",
                                          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      end
    end
  end

  def import_xlsx
    if params[:file].present?
      begin
        xlsx = Roo::Excelx.new(params[:file].path)
        headers = xlsx.row(1).map { |h| h.to_s.strip }

        return redirect_to super_admin_subscription_tiers_path, flash: { error: 'File trống' } if xlsx.last_row.nil? || xlsx.last_row < 2

        (2..xlsx.last_row).each do |i|
          row = Hash[[headers, xlsx.row(i)].transpose]
          tier = SubscriptionTier.find_or_initialize_by(name_en: row['name_en'])
          tier.name_vi = row['name_vi'] if row['name_vi'].present?
          tier.description_en = row['description_en']
          tier.description_vi = row['description_vi']
          tier.limits = row['limits'].present? ? JSON.parse(row['limits']) : {}
          tier.features = row['features'].present? ? JSON.parse(row['features']) : {}
          tier.visible = row['visible'] == 'true' || row['visible'] == '1' if row['visible'].present?
          tier.is_free = row['is_free'] == 'true' || row['is_free'] == '1' if row['is_free'].present?
          tier.save!
        end
        flash[:notice] = 'Nhập dữ liệu Tiers thành công.'
      rescue StandardError => e
        flash[:error] = "Lỗi khi nhập XLSX: #{e.message}"
      end
    else
      flash[:error] = 'Vui lòng chọn tệp XLSX để tải lên.'
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
