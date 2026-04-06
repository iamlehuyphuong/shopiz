class RenameTiktokToTiktokShop < ActiveRecord::Migration[7.1]
  def up
    rename_table :channel_tiktok, :channel_tiktok_shop
    Inbox.where(channel_type: 'Channel::Tiktok').update_all(channel_type: 'Channel::TiktokShop')
  end

  def down
    rename_table :channel_tiktok_shop, :channel_tiktok
    Inbox.where(channel_type: 'Channel::TiktokShop').update_all(channel_type: 'Channel::Tiktok')
  end
end
