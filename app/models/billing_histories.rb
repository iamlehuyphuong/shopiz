# == Schema Information
#
# Table name: billing_histories
#
#  id                    :bigint           not null, primary key
#  description           :string
#  metadata              :jsonb
#  price_amount          :bigint
#  price_currency        :string
#  product_name          :string
#  sku                   :string
#  status                :integer
#  transaction_date_time :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  product_id            :string           not null
#  transaction_id        :string
#
# Indexes
#
#  index_billing_histories_on_account_id  (account_id)
#
class BillingHistories < ApplicationRecord
  belongs_to :account

  enum status: { pending: 0, invoiced: 1, overdue: 2 }
end
