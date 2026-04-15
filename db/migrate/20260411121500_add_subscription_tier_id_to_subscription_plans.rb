class AddSubscriptionTierIdToSubscriptionPlans < ActiveRecord::Migration[7.1]
  def change
    add_reference :subscription_plans, :subscription_tier, foreign_key: true
  end
end
