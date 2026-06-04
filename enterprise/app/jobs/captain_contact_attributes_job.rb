class CaptainContactAttributesJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    account = conversation.account
    return unless account.feature_enabled?('captain_copilot') || account.feature_enabled?('captain_assistant')

    # ContactAttributesService needs an assistant instance.
    # In general Shopiz usage, we pass a dummy or the default assistant config if any.
    # Assuming the Assistant parameter provides .id, .feature_contact_attributes for telemetry and prompts
    assistant = account.captain_assistant || Captain::Assistant.new(id: 0, account: account)

    Captain::Llm::ContactAttributesService.new(assistant, conversation).generate_and_update_attributes
  end
end
