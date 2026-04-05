# frozen_string_literal: true

class SuperAdmin::AddonPackagesController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  private

  def resource_params
    params.require(:addon_package).permit(
      :name, :addon_type, :quantity, :price_amount, :currency, :duration_days, :visible
    )
  end
end
