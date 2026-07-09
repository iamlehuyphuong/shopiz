class AddIsDefaultForNewAccountToSubscriptionPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :subscription_plans, :is_default_for_new_account, :boolean, default: false
  end
end
