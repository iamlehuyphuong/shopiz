# frozen_string_literal: true

class SuperAdmin::SubscriptionPlansController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  private

  def resource_params
    params.require(:subscription_plan).permit(
      :name_en, :name_vi, :description_en, :description_vi,
      :price_amount, :currency, :duration_days, :visible,
      limits: {}, features: {}
    )
  end
end
