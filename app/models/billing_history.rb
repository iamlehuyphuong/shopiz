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
class BillingHistory < ApplicationRecord
  belongs_to :account

  enum status: { pending: 0, invoiced: 1, overdue: 2, cancelled: 3, expired: 4, completed: 5 }

  def content
    if metadata['type'] == 'package'
      I18n.t('billing_histories.content.package', product_name: product_name.upcase, month: metadata['months'])
    else
      I18n.t('billing_histories.content.credit', product_name: product_name.upcase)
    end
  end

  def created_date_formatted
    created_at.strftime('%d %b %Y')
  end

  def amount_formatted
    ActionController::Base.helpers.number_to_currency(
      price_amount,
      unit: 'đ',
      precision: 0,
      delimiter: '.',
      format: '%n%u'
    )
  end

  def status_text
    I18n.t("billing_histories.statuses.#{status}")
  end
end
