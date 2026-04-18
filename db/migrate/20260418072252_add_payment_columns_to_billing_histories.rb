class AddPaymentColumnsToBillingHistories < ActiveRecord::Migration[7.1]
  def change
    add_column :billing_histories, :order_id, :string
    add_index :billing_histories, :order_id
    add_column :billing_histories, :payment_method, :string
    add_column :billing_histories, :checkout_url, :string
    add_column :billing_histories, :gateway_payload, :jsonb
    add_column :billing_histories, :paid_at, :datetime
  end
end
