class ZaloPersonal::UndoMessageService
  def initialize(message)
    @message = message
    @conversation = @message.conversation
  end

  def perform
    body = {
      msgId: @message.additional_attributes['msgId'],
      cliMsgId: @message.additional_attributes['cliMsgId'],
      threadId: @conversation.contact_inbox.source_id,
      type: @conversation.zalo_group? ? 1 : 0,
      ownId: @message.inbox.channel.oa_id
    }

    response = HTTParty.post(
      undo_url,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )
    raise StandardError, 'Fail request' unless response['success']

    @message.update!(content: I18n.t('conversations.messages.undo'), content_type: :text, content_attributes: { undo: true })
    @message.attachments.destroy_all

    { status: response['success'] }
  end

  def undo_url
    "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/undoMessage"
  end
end
