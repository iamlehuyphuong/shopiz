class Captain::AutoLabelJob < ApplicationJob
  queue_as :low

  def perform(conversation_id, message_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?
    return unless conversation.account.feature_enabled?('captain_tasks')

    # Abort if this message is no longer the last incoming message
    last_incoming = conversation.messages.incoming.last
    return if last_incoming.blank? || last_incoming.id != message_id

    # Call LabelSuggestionService
    service = Captain::LabelSuggestionService.new(
      account: conversation.account,
      conversation_display_id: conversation.display_id,
      skip_cache: true
    )

    # We don't want to use cache, we just want to execute.
    # The current service reads from cache. Let's bypass cache or just let it cache.
    result = service.perform
    return if result.blank? || result[:error].present? || result[:message].blank?

    # Assign labels
    # result[:message] contains comma separated labels
    suggested_labels = result[:message].split(',').map(&:strip)
    return if suggested_labels.empty?

    # Verify labels exist
    valid_labels = conversation.account.labels.where(title: suggested_labels).pluck(:title)
    return if valid_labels.empty?

    conversation.label_list.add(*valid_labels)
    conversation.save!
  end
end
