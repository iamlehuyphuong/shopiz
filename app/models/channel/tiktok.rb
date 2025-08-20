# == Schema Information
#
# Table name: channel_tiktok
#
#  id            :bigint           not null, primary key
#  access_token  :string           not null
#  expires_in    :integer          not null
#  refresh_token :string           not null
#  shop_cipher   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  shop_id       :string           not null
#
# Indexes
#
#  index_channel_tiktok_on_shop_cipher  (shop_cipher) UNIQUE
#  index_channel_tiktok_on_shop_id      (shop_id) UNIQUE
#

class Channel::Tiktok < ApplicationRecord
  include Channelable

  self.table_name = 'channel_tiktok'
  EDITABLE_ATTRS = [:access_token, :refresh_token, :expires_in].freeze

  validates :access_token, presence: true, length: { maximum: 2048 }
  validates :refresh_token, presence: true, length: { maximum: 2048 }
  validates :expires_in, presence: true
  validates :account_id, presence: true
  validates :shop_id, presence: true, uniqueness: true
  validates :shop_cipher, presence: true, uniqueness: true

  def name
    'Tiktok'
  end
end
