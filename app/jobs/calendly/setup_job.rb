# Background job to verify Calendly PAT and populate hook settings.
# Triggered after an Integrations::Hook with app_id 'calendly' is created.
class Calendly::SetupJob < ApplicationJob
  queue_as :default

  def perform(hook_id)
    hook = Integrations::Hook.find_by(id: hook_id)
    return if hook.blank? || hook.disabled? || hook.app_id != 'calendly'

    Calendly::SetupService.new(hook).setup
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: hook&.account).capture_exception
    Rails.logger.error "Calendly::SetupJob failed for hook ##{hook_id}: #{e.message}"
  end
end
