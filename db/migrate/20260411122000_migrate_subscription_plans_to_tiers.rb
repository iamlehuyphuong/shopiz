class MigrateSubscriptionPlansToTiers < ActiveRecord::Migration[7.1]
  def up
    # Iterate through current subscription_plans, and map them to subscription_tiers based on name_en
    SubscriptionPlan.find_each do |plan|
      tier = SubscriptionTier.find_or_initialize_by(name_en: plan.read_attribute(:name_en))
      tier.name_vi = plan.read_attribute(:name_vi)
      tier.description_en = plan.read_attribute(:description_en)
      tier.description_vi = plan.read_attribute(:description_vi)
      tier.limits = plan.read_attribute(:limits) || {}
      tier.features = plan.read_attribute(:features) || {}
      tier.is_free = plan.read_attribute(:is_free)
      tier.visible = plan.read_attribute(:visible)
      tier.save!

      plan.update_column(:subscription_tier_id, tier.id)
    end

    # Remove the columns from subscription_plans after data is moved
    remove_column :subscription_plans, :name_en
    remove_column :subscription_plans, :name_vi
    remove_column :subscription_plans, :description_en
    remove_column :subscription_plans, :description_vi
    remove_column :subscription_plans, :limits
    remove_column :subscription_plans, :features
    remove_column :subscription_plans, :is_free
  end

  def down
    add_column :subscription_plans, :name_en, :string
    add_column :subscription_plans, :name_vi, :string
    add_column :subscription_plans, :description_en, :text
    add_column :subscription_plans, :description_vi, :text
    add_column :subscription_plans, :limits, :jsonb, default: {}
    add_column :subscription_plans, :features, :jsonb, default: {}
    add_column :subscription_plans, :is_free, :boolean, default: false

    SubscriptionPlan.reset_column_information
    SubscriptionPlan.find_each do |plan|
      tier = SubscriptionTier.find_by(id: plan.subscription_tier_id)
      next unless tier

      plan.update_columns(
        name_en: tier.name_en,
        name_vi: tier.name_vi,
        description_en: tier.description_en,
        description_vi: tier.description_vi,
        limits: tier.limits,
        features: tier.features,
        is_free: tier.is_free
      )
    end
  end
end
