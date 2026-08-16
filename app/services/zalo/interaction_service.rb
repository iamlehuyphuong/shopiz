# Processes interaction events from Zalo OA webhook (e.g. user_click_chatnow)
# Creates a private message in conversation and sends greeting message if enabled
class Zalo::InteractionService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    set_conversation

    if %w[user_click_text_button user_click_image_button].include?(params[:event_name])
      create_incoming_message
    else
      create_private_message

      send_greeting_message if params[:event_name] == 'user_click_chatnow' && @inbox.greeting_enabled? && @inbox.greeting_message.present?
    end
  end

  private

  def account
    @account ||= @inbox.account
  end

  def sender_id
    params[:user_id] || params.dig(:sender, :id)
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: sender_id,
      inbox: @inbox,
      contact_attributes: { name: sender_id }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
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

    @conversation = ::Conversation.create!(conversation_params)
  end

  def create_incoming_message
    @message = @conversation.messages.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      content: params[:message]&.dig(:text),
      sender: @contact
    )
  end

  def create_private_message
    message_content = case params[:event_name]
                      when 'user_click_chatnow'
                        I18n.t('inboxes.zalo.interaction.chatnow_clicked')
                      else
                        I18n.t('inboxes.zalo.interaction.other_interaction', event_name: params[:event_name])
                      end

    @message = @conversation.messages.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :activity,
      content: message_content,
      private: true
    )
  end

  def send_greeting_message
    # Create outgoing message in Chatwoot
    outgoing_message = @conversation.messages.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :outgoing,
      content: @inbox.greeting_message
    )

    # Deliver to Zalo
    ::Zalo::SendOnZaloService.new(message: outgoing_message).perform
  end
end
