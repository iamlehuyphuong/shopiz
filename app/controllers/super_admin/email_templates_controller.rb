require 'csv'

class SuperAdmin::EmailTemplatesController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   super
  #   send_foo_updated_email(requested_resource)
  # end

  def export_csv
    respond_to do |format|
      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          csv << ["name", "body", "account_id", "template_type", "locale"]
          EmailTemplate.find_each do |record|
            csv << [
              record.name,
              record.body,
              record.account_id,
              record.template_type,
              record.locale
            ]
          end
        end
        send_data csv_data, filename: "email_templates_#{Date.today}.csv"
      end
    end
  end

  def import_csv
    if params[:file].present?
      begin
        CSV.foreach(params[:file].path, headers: true) do |row|
          template = EmailTemplate.find_or_initialize_by(
            name: row["name"], 
            account_id: row["account_id"].presence
          )
          
          template.body = row["body"] if row.key?("body")
          template.template_type = row["template_type"] if row.key?("template_type")
          template.locale = row["locale"] if row.key?("locale")
          
          template.save!
        end
        flash[:notice] = "Nhập dữ liệu Email Templates thành công."
      rescue => e
        flash[:error] = "Lỗi khi nhập CSV: #{e.message}"
      end
    else
      flash[:error] = "Vui lòng chọn tệp CSV để tải lên."
    end
    redirect_to super_admin_email_templates_path
  end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #
  # def resource_params
  #   params.require(resource_class.model_name.param_key).
  #     permit(dashboard.permitted_attributes).
  #     transform_values { |value| value == "" ? nil : value }
  # end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information
end
