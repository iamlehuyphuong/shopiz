class Zalo::GroupWebhookService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    set_conversation

    if incoming_message_event?
      create_incoming_message
    else
      create_system_message
      trigger_sync_job_if_needed
    end
  end

  private

  def group_id
    params.dig(:source, :group_id) || params[:group_id]
  end

  def set_contact
    # Contact representing the Zalo Group
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: group_id,
      inbox: @inbox,
      contact_attributes: {
        name: "Nhóm Zalo: #{group_id}",
        custom_attributes: { 'is_zalo_group' => true }
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved)
                                    .order(updated_at: :asc).last
                    end

    return if @conversation

    @conversation = ::Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    )
  end

  def incoming_message_event?
    Webhooks::ZaloEventsJob::INCOMING_MESSAGE_EVENTS.include?(params[:event_name])
  end

  def create_incoming_message
    # TODO: Handle attachments if needed, for now just text
    message_content = params.dig(:message, :text) || ''
    sender_id = params.dig(:sender, :id) || 'Unknown'

    content = "[#{sender_id}]: #{message_content}"

    @conversation.messages.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      content: content,
      sender: @contact
    )
  end

  def create_system_message
    event_name = params[:event_name]
    content = "Sự kiện nhóm: #{event_name}"

    @conversation.messages.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :activity,
      content: content,
      private: true
    )
  end

  def trigger_sync_job_if_needed
    sync_events = %w[
      create_group user_join_group user_leave_group
      add_group_admin remove_group_admin update_group_info
    ]

    return unless sync_events.include?(params[:event_name])

    Zalo::SyncGroupMembersJob.perform_later(@conversation.id)
  end
end
