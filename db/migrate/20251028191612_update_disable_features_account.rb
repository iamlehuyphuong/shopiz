class UpdateDisableFeaturesAccount < ActiveRecord::Migration[7.1]
  def change
    Account.all.each do |account|
      account.disable_features!(*Featurable::DISABLED_FEATURES)
    end
  end
end
