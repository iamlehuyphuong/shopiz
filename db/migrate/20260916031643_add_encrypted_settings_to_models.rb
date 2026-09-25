class AddEncryptedSettingsToModels < ActiveRecord::Migration[7.1]
  def up
    add_column :accounts, :encrypted_settings, :text
    add_column :integrations_hooks, :encrypted_settings, :text

    rename_column :captain_custom_tools, :auth_config, :auth_config_legacy
    add_column :captain_custom_tools, :encrypted_auth_config, :text

    # Data migration for Captain::CustomTool
    # Note: We must use the model to trigger ActiveRecord::Encryption.
    # Since models could change in the future, we define temporary models here.

    # 1. captain_custom_tools
    ActiveRecord::Base.connection.execute('SELECT id, auth_config_legacy FROM captain_custom_tools WHERE auth_config_legacy IS NOT NULL').each do |row|
      auth_config_legacy = JSON.parse(row['auth_config_legacy'])
      # We need to manually encrypt it if we want to write it back using SQL,
      # but the easiest way is to use the model. Let's use the actual model since encryption is tied to it.
      tool = Captain::CustomTool.find_by(id: row['id'])
      tool.update_column(:encrypted_auth_config, tool.class.type_for_attribute(:encrypted_auth_config).serialize(auth_config_legacy)) if tool
    rescue JSON::ParserError
      # skip invalid json
    end
    remove_column :captain_custom_tools, :auth_config_legacy

    # 2. accounts
    ActiveRecord::Base.connection.execute("SELECT id, settings FROM accounts WHERE settings IS NOT NULL AND (settings ? 'sales_payment_config' OR settings ? 'custom_email_config')").each do |row|
      settings = JSON.parse(row['settings'])
      encrypted = {}
      encrypted['sales_payment_config'] = settings.delete('sales_payment_config') if settings.key?('sales_payment_config')
      encrypted['custom_email_config'] = settings.delete('custom_email_config') if settings.key?('custom_email_config')

      if encrypted.present?
        # Save to DB
        account = Account.find_by(id: row['id'])
        if account
          account.update_columns(
            encrypted_settings: account.class.type_for_attribute(:encrypted_settings).serialize(encrypted),
            settings: settings
          )
        end
      end
    rescue JSON::ParserError
      # skip
    end

    # 3. integrations_hooks
    ActiveRecord::Base.connection.execute("SELECT id, settings FROM integrations_hooks WHERE settings IS NOT NULL AND settings ? 'api_key'").each do |row|
      settings = JSON.parse(row['settings'])
      encrypted = {}
      encrypted['api_key'] = settings.delete('api_key') if settings.key?('api_key')

      if encrypted.present?
        hook = Integrations::Hook.find_by(id: row['id'])
        if hook
          hook.update_columns(
            encrypted_settings: hook.class.type_for_attribute(:encrypted_settings).serialize(encrypted),
            settings: settings
          )
        end
      end
    rescue JSON::ParserError
      # skip
    end
  end

  def down
    remove_column :accounts, :encrypted_settings
    remove_column :integrations_hooks, :encrypted_settings
    add_column :captain_custom_tools, :auth_config, :jsonb, default: {}
    remove_column :captain_custom_tools, :encrypted_auth_config
  end
end
