# frozen_string_literal: true

class Captain::Conversation::CommentReplyBuilderJob < ApplicationJob
  queue_as :default

  SUPPORTED_CHANNELS = [Channel::FacebookPage, Channel::Instagram, Channel::Tiktok].freeze

  def perform(conversation_id, comment_id:, post_id:, message:, platform:, comment_created_at: nil)
    @conversation = Conversation.find_by(id: conversation_id)
    return unless @conversation

    @channel = @conversation.inbox.channel
    return unless supported_channel?
    return if comment_too_old?(comment_id, comment_created_at)

    generated_text = generate_reply_text(message, post_id, platform)
    
    if generated_text.blank?
      msg = @conversation.messages.create!(
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        message_type: :outgoing,
        content: 'AI Assistant failed to generate a reply.',
        status: :failed,
        source_id: "failed_ai_#{SecureRandom.hex(4)}",
        content_attributes: { is_private_reply: true }
      )
      Messages::StatusUpdateService.new(msg, 'failed', 'AI Generation Failed or not configured.').perform
      return
    end

    send_reply(comment_id, generated_text)
  end

  private

  def supported_channel?
    SUPPORTED_CHANNELS.any? { |klass| @channel.is_a?(klass) }
  end

  def comment_too_old?(comment_id, comment_created_at)
    return false if comment_created_at.blank?

    created_time = Time.zone.at(comment_created_at.to_i)
    return false unless created_time < 7.days.ago

    Rails.logger.warn "[CommentReply] Skipping AI reply for #{comment_id} — comment older than 7 days"
    true
  rescue StandardError
    false
  end

  def send_reply(comment_id, text)
    if @channel.is_a?(Channel::Tiktok)
      send_tiktok_comment_reply(comment_id, text)
    else
      action_service_for_channel.send_private_reply_and_log(comment_id, text, @conversation)
    end
  end

  def action_service_for_channel
    if @channel.is_a?(Channel::FacebookPage)
      Facebook::CommentActionService.new(channel: @channel)
    else
      Instagram::CommentActionService.new(channel: @channel)
    end
  end

  def generate_reply_text(customer_message, post_id, platform)
    prompt_config = @channel.provider_config['auto_reply_ai_prompt'] || 'Hãy viết một tin nhắn ngắn gọn, thân thiện, trả lời khách hàng.'
    reply_method = platform == 'tiktok' ? 'bình luận công khai' : 'tin nhắn riêng tư (Direct Message)'

    system_prompt = <<~PROMPT
      Bạn là trợ lý chăm sóc khách hàng của trang #{platform.capitalize}.
      Nhiệm vụ: Phản hồi bình luận của khách hàng thông qua #{reply_method}.

      Yêu cầu từ cửa hàng:
      #{prompt_config}

      Thông tin khách hàng:
      Bài viết ID: #{post_id}
      Bình luận: "#{customer_message}"

      Trả về DUY NHẤT nội dung tin nhắn bạn sẽ gửi cho khách, không kèm theo giải thích hay định dạng thừa.
    PROMPT

    completion = ::Captain::LLM::Builder.new
                                        .with_system_message(system_prompt)
                                        .with_user_message('Xin hãy tạo tin nhắn phản hồi dựa trên bình luận của tôi.')
                                        .execute

    completion&.strip
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    nil
  end

  def send_tiktok_comment_reply(comment_id, text)
    client = Tiktok::Client.new(business_id: @channel.business_id, access_token: @channel.validated_access_token)
    reply_id = client.send_comment_reply(comment_id, text)

    return if reply_id.blank?

    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: text,
      source_id: reply_id
    )
  rescue StandardError => e
    Rails.logger.error "[TikTok] Error sending AI comment reply for #{comment_id}: #{e.message}"
  end
end
