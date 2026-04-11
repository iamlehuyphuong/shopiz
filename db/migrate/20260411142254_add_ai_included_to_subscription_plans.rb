class AddAiIncludedToSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_plans, :ai_included, :boolean, default: false
  end
end
