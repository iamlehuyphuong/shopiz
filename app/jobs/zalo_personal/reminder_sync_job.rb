module ZaloPersonal
  class ReminderSyncJob < ApplicationJob
    queue_as :default

    def perform(conversation_id, action, sync_enabled)
      conversation = Conversation.find_by(id: conversation_id)
      return unless conversation
      return unless sync_enabled

      channel = conversation.inbox&.channel
      return unless channel.is_a?(Channel::ZaloPersonal)

      case action.to_sym
      when :create then channel.sync_create_reminder(conversation)
      when :edit   then channel.sync_edit_reminder(conversation)
      when :remove then channel.sync_remove_reminder(conversation)
      end
    end
  end
end
