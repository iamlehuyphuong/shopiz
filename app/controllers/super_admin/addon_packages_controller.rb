# frozen_string_literal: true

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

  private

  def resource_params
    params.require(:addon_package).permit(
      :sku, :name, :addon_type, :quantity, :price_amount, :currency, :duration_days, :visible
    )
  end
end
