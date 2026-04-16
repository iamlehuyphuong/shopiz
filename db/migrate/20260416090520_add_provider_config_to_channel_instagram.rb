class AddProviderConfigToChannelInstagram < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_instagram, :provider_config, :jsonb, default: {}
  end
end
