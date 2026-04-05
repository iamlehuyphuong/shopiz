# frozen_string_literal: true

# == Schema Information
#
# Table name: addon_packages
#
#  id            :bigint           not null, primary key
#  addon_type    :integer          not null
#  currency      :string           default("vnd")
#  duration_days :integer
#  name          :string           not null
#  price_amount  :decimal(15, 2)   default(0.0)
#  quantity      :integer          not null
#  visible       :boolean          default(TRUE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class AddonPackage < ApplicationRecord
  enum addon_type: { ai_messages: 0, staff: 1, inboxes_count: 2 }

  validates :name, :addon_type, :quantity, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :price_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :visible, -> { where(visible: true) }
end
