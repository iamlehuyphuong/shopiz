class Omicall::SetupWebhookJob < ApplicationJob
  queue_as :default

  def perform(hook_id)
    hook = Integrations::Hook.find_by(id: hook_id)
    return unless hook

    account = hook.account
    return unless account

    service = Omicall::CallService.new(account)
    response = service.register_webhook

    if response.is_a?(Hash) && response[:error].present?
      Rails.logger.error "OmiCall SetupWebhookJob Failed: #{response[:error]}"
    else
      Rails.logger.info "OmiCall SetupWebhookJob Success: #{response.inspect}"
    end
  end
end
