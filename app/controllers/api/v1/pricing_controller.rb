class Api::V1::PricingController < Api::BaseController
  skip_before_action :authenticate_user!, :authenticate_access_token!, :validate_bot_access_token!, raise: false

  def index
    tiers = SubscriptionTier.visible.includes(:subscription_plans).order(:created_at)
    addons = AddonPackage.visible.order(:created_at)

    render json: {
      tiers: tiers.map do |tier|
        {
          id: tier.id,
          name_en: tier.name_en,
          name_vi: tier.name_vi,
          description_en: tier.description_en,
          description_vi: tier.description_vi,
          limits: tier.limits,
          features: tier.features,
          is_free: tier.is_free?,
          plans: tier.subscription_plans.visible.map do |plan|
            {
              id: plan.id,
              sku: plan.sku,
              duration_days: plan.duration_days,
              price_amount: plan.price_amount,
              currency: plan.currency,
              ai_included: plan.ai_included
            }
          end
        }
      end,
      addons: addons.map do |addon|
        {
          id: addon.id,
          sku: addon.sku,
          name: addon.name,
          name_en: addon.name_en,
          name_vi: addon.name_vi,
          addon_type: addon.addon_type,
          quantity: addon.quantity,
          price_amount: addon.price_amount,
          duration_days: addon.duration_days,
          currency: addon.currency
        }
      end
    }
  end
end
