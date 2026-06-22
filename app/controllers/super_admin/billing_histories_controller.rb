class SuperAdmin::BillingHistoriesController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, if you want to add pagination or change the order:
  #
  # def index
  #   super
  #   @resources = BillingHistories.
  #     page(params[:page]).
  #     per(10)
  # end

  def scoped_resource
    resource_class.where('price_amount > 0')
  end
end
