class Enterprise::CreateVnpayCustomerJob < ApplicationJob
  queue_as :default

  def perform(account)
    Enterprise::Billing::CreateVnpayCustomerService.new(account: account).perform
  end
end
