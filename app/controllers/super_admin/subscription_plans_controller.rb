# frozen_string_literal: true

class SuperAdmin::SubscriptionPlansController < SuperAdmin::ApplicationController
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
    params.require(:subscription_plan).permit(
      :sku, :name_en, :name_vi, :description_en, :description_vi,
      :price_amount, :currency, :duration_days, :visible, :is_free,
      limits: {}, features: {}
    )
  end
end
