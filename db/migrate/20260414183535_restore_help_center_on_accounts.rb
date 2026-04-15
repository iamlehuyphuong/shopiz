class RestoreHelpCenterOnAccounts < ActiveRecord::Migration[7.1]
  def change
    Account.find_each do |account|
      account.enable_features!('help_center')
    end
  end
end
