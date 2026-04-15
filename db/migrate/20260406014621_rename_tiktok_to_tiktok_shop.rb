class RenameTiktokToTiktokShop < ActiveRecord::Migration[7.1]
  def up
    # No-op: channel_tiktok and channel_tiktok_shop are separate channels
  end

  def down
    # No-op
  end
end
