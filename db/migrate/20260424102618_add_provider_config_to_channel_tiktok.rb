class AddProviderConfigToChannelTiktok < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_tiktok, :provider_config, :jsonb, default: {}
  end
end
