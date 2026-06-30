class Omicall::TeardownWebhookJob < ApplicationJob
  queue_as :default

  def perform(account_id, api_key)
    account = Account.find_by(id: account_id)
    return unless account

    # Reset SIP configurations for all agents when disconnecting
    account.omicall_sip_infos.delete_all

    return if api_key.blank?

    service = Omicall::CallService.new(account, api_key: api_key)
    response = service.unregister_webhook

    if response.is_a?(Hash) && response[:error].present?
      Rails.logger.error "OmiCall TeardownWebhookJob Failed: #{response[:error]}"
    else
      Rails.logger.info "OmiCall TeardownWebhookJob Success: #{response.inspect}"
    end
  end
end
