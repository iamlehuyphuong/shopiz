class Webhooks::FacebookPostbackJob < ApplicationJob
  queue_as :default

  def perform(message)
    Integrations::Facebook::Postback.new(message).perform
  end
end
