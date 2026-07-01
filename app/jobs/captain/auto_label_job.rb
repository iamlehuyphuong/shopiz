class Captain::AutoLabelJob < ApplicationJob
  queue_as :low

  def perform(conversation_id, trigger_type)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?
    return unless conversation.account.feature_enabled?('captain_tasks')

    # If triggered by 'delay', check if 15 minutes have passed since last incoming message
    if trigger_type == 'delay'
      last_incoming = conversation.messages.incoming.last
      return if last_incoming.blank?
      return if last_incoming.created_at > 15.minutes.ago
    end

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
