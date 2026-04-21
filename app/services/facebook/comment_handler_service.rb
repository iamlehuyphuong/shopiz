# frozen_string_literal: true

class Facebook::CommentHandlerService
  def initialize(channel:, contact_id:, contact_name:, comment_id:, post_id:, message:)
    @channel = channel
    @inbox = channel.inbox
    @contact_id = contact_id
    @contact_name = contact_name
    @comment_id = comment_id
    @post_id = post_id
    @message = message
  end

  def perform
    return unless @contact_id.present?

    ActiveRecord::Base.transaction do
      build_contact_inbox
      build_conversation
      log_internal_note
    end

    @conversation
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    nil
  end

  private

  def build_contact_inbox
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: @contact_id,
      inbox: @inbox,
      contact_attributes: { name: @contact_name }
    ).perform
  end

  def build_conversation
    # If lock to single conversation is enabled, find the latest conversation or build a new one.
    if @inbox.lock_to_single_conversation
      @conversation = Conversation.where(conversation_params).order(created_at: :desc).first || build_new_conversation
    else
      last_conversation = Conversation.where(conversation_params).where.not(status: :resolved).order(created_at: :desc).first
      @conversation = last_conversation || build_new_conversation
    end
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact_inbox.contact_id
    }
  end

  def build_new_conversation
    Conversation.create!(
      conversation_params.merge(
        contact_inbox_id: @contact_inbox.id,
        additional_attributes: { type: 'comment' }
      )
    )
  end

  def log_internal_note
    note_content = "Post ID: #{@post_id}\n"
    note_content += "Comment ID: #{@comment_id}\n"
    note_content += "Message: #{@message}"

    # Verify if this exact note already exists to prevent duplication on multiple webhook deliveries
    return if @conversation.messages.where(message_type: :outgoing, private: true, content: note_content).exists?

    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      private: true,
      content: note_content
    )
  end
end
