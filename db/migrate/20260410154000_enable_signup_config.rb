class EnableSignupConfig < ActiveRecord::Migration[7.0]
  def up
    # Enable global signup
    config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
    config.value = true
    config.locked = false
    config.save!

    # Enable creating new accounts from dashboard as well, as it's often desired when signup is enabled
    dashboard_config = InstallationConfig.find_or_initialize_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
    dashboard_config.value = true
    dashboard_config.locked = false
    dashboard_config.save!

    GlobalConfig.clear_cache
  end

  def down
    # We won't strictly revert to false as it might have been manually changed
    # but we can leave this empty or provide a reversal if needed.
  end
end
