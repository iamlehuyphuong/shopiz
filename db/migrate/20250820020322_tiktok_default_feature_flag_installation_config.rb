class TiktokDefaultFeatureFlagInstallationConfig < ActiveRecord::Migration[7.0]
  def up
    # Update the default feature flag config to enable chatwoot_v4
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config && config.value.present?
      features = config.value.map do |f|
        if f['name'] == 'channel_tiktok'
          f.merge('enabled' => true)
        else
          f
        end
      end
      config.value = features
      config.save!
    end

    # Enable channel_tiktok for all accounts in batches of 100
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('channel_tiktok') }
    end

    GlobalConfig.clear_cache
  end
end
