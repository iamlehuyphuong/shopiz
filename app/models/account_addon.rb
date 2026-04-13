# frozen_string_literal: true

# == Schema Information
#
# Table name: account_addons
#
#  id               :bigint           not null, primary key
#  addon_type       :integer          not null
#  expired_at       :datetime
#  purchased_at     :datetime         not null
#  quantity         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  addon_package_id :bigint           not null
#
# Indexes
#
#  index_account_addons_on_account_id        (account_id)
#  index_account_addons_on_addon_package_id  (addon_package_id)
#  index_account_addons_on_addon_type        (addon_type)
#  index_account_addons_on_expired_at        (expired_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (addon_package_id => addon_packages.id)
#
class AccountAddon < ApplicationRecord
  belongs_to :account
  belongs_to :addon_package

  enum addon_type: { ai_messages: 0, staff: 1, inboxes_count: 2 }

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :purchased_at, presence: true

  scope :active, -> { where('expired_at IS NULL OR expired_at > ?', Time.current) }
end
