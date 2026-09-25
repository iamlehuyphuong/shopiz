class DropAccountSamlSettingsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :account_saml_settings, if_exists: true
  end
end
