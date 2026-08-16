class Zalo::SyncGroupMembersJob < ApplicationJob
  queue_as :default

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    Zalo::SyncGroupMembersService.new(conversation).perform
  end
end
