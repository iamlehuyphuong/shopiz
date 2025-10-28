class ChangeFeatureFlagToBigint < ActiveRecord::Migration[7.1]
  def change
    change_column :accounts, :feature_flags, :bigint, default: 0, null: false
  end
end
