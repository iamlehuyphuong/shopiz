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

  # Define a custom finder to handle the "subclasses" of BillingHistories if any
end
