class AddProviderConfigToChannelZaloPersonal < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_zalo_personal, :provider_config, :jsonb, default: {}
  end
end
