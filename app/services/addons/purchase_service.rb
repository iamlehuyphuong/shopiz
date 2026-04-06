# frozen_string_literal: true

class Addons::PurchaseService
  def initialize(account, addon_package)
    @account = account
    @addon_package = addon_package
  end

  def execute
    ActiveRecord::Base.transaction do
      create_account_addon
      update_account_resources
      log_transaction
    end
    true
  rescue StandardError => e
    Rails.logger.error("Addon Purchase Error: #{e.message}")
    false
  end

  private

  def create_account_addon
    expiration = nil
    expiration = Time.current + @addon_package.duration_days.days if @addon_package.duration_days.present?

    @account_addon = @account.account_addons.create!(
      addon_package: @addon_package,
      addon_type: @addon_package.addon_type,
      quantity: @addon_package.quantity,
      purchased_at: Time.current,
      expired_at: expiration
    )
  end

  def update_account_resources
    Subscriptions::ProvisioningService.new(@account).execute
  end

  def log_transaction
    # Note: BillingHistory model expects product_id, product_name, sku, status, price_amount, price_currency, transaction_date_time, etc.
    BillingHistory.create!(
      account: @account,
      product_id: "ADDON_#{@addon_package.id}",
      product_name: @addon_package.name,
      sku: "ADDON_#{@addon_package.id}",
      price_amount: @addon_package.price_amount,
      price_currency: @addon_package.currency,
      status: :invoiced,
      transaction_date_time: Time.current.to_s,
      description: "Purchased Addon: #{@addon_package.name} (Qty: #{@addon_package.quantity})",
      metadata: { 
        type: 'addon',
        addon_id: @addon_package.id,
        quantity: @addon_package.quantity,
        type_name: @addon_package.addon_type
      }
    )
  end
end
