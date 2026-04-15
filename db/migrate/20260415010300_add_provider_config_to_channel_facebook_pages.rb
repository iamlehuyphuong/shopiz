class AddProviderConfigToChannelFacebookPages < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_facebook_pages, :provider_config, :jsonb, default: {}, null: false
  end
end
