class SuperAdmin::AccountsController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   super
  #   send_foo_updated_email(requested_resource)
  # end

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
  def resource_params
    permitted_params = super
    permitted_params[:limits] = permitted_params[:limits].to_h.compact
    permitted_params[:feature_names] = params[:enabled_features].keys if params[:enabled_features].present?
    permitted_params
  end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  def seed
    Internal::SeedAccountJob.perform_later(requested_resource)
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account seeding triggered')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def reset_cache
    requested_resource.reset_cache_keys
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Cache keys cleared')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def destroy
    account = Account.find(params[:id])

    DeleteObjectJob.perform_later(account) if account.present?
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account deletion is in progress.')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def subscribe
    account = Account.find(params[:id])

    if params[:is_custom] == 'true'
      base_plan = SubscriptionPlan.find(params[:base_plan_id])

      custom_tier = SubscriptionTier.create!(
        name_en: "Custom Tier for Account #{account.id}",
        name_vi: "Gói Tuỳ chỉnh cho Tài khoản #{account.id}",
        description_en: "Custom limits based on #{base_plan.name_en}",
        description_vi: "Gói tuỳ chỉnh dựa trên #{base_plan.name_vi}",
        limits: params[:custom_limits].to_unsafe_h.transform_values(&:to_i),
        features: base_plan.subscription_tier.features,
        visible: false,
        is_free: false
      )

      plan = SubscriptionPlan.create!(
        subscription_tier: custom_tier,
        price_amount: params[:custom_price_amount].to_f,
        currency: base_plan.currency,
        duration_days: params[:custom_duration_days].to_i,
        ai_included: base_plan.ai_included,
        sku: "CUSTOM-#{account.id}-#{Time.current.to_i}",
        visible: false
      )
    else
      plan = SubscriptionPlan.find(params[:plan_id])
    end

    status = Subscriptions::SubscribeService.new(account, plan).execute
    message = status ? 'Plan subscribed successfully!' : 'Failed to subscribe plan.'
    redirect_to super_admin_account_path(account), notice: message
  end

  def purchase_addon
    account = Account.find(params[:id])
    addon_package = AddonPackage.find(params[:addon_package_id])
    status = Addons::PurchaseService.new(account, addon_package).execute
    message = status ? 'Addon purchased successfully!' : 'Failed to purchase addon.'
    redirect_to super_admin_account_path(account), notice: message
  end
end

SuperAdmin::AccountsController.prepend_mod_with('SuperAdmin::AccountsController')
