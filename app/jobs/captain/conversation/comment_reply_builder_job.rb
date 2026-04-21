# frozen_string_literal: true

class Captain::Conversation::CommentReplyBuilderJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, comment_id:, post_id:, message:, platform:)
    @conversation = Conversation.find_by(id: conversation_id)
    return unless @conversation

    @channel = @conversation.inbox.channel
    return unless @channel.is_a?(Channel::FacebookPage) || @channel.is_a?(Channel::Instagram)

    # 1. Generate text using AI
    generated_text = generate_reply_text(message, post_id, platform)
    return if generated_text.blank?

    # 2. Send via CommentActionService and log the message
    action_service = if @channel.is_a?(Channel::FacebookPage)
                       Facebook::CommentActionService.new(channel: @channel)
                     else
                       Instagram::CommentActionService.new(channel: @channel)
                     end

    action_service.send_private_reply_and_log(comment_id, generated_text, @conversation)
  end

  private

  def generate_reply_text(customer_message, post_id, platform)
    prompt_config = @channel.provider_config['auto_reply_ai_prompt'] || 'Hãy viết một tin nhắn ngắn gọn, thân thiện, trả lời khách hàng.'
    
    system_prompt = <<~PROMPT
      Bạn là trợ lý chăm sóc khách hàng của trang #{platform.capitalize}.
      Nhiệm vụ: Phản hồi bình luận của khách hàng thông qua tin nhắn riêng tư (Direct Message).
      
      Yêu cầu từ cửa hàng:
      #{prompt_config}
      
      Thông tin khách hàng:
      Bài viết ID: #{post_id}
      Bình luận: "#{customer_message}"
      
      Trả về DUY NHẤT nội dung tin nhắn bạn sẽ gửi cho khách, không kèm theo giải thích hay định dạng thừa.
    PROMPT

    completion = ::Captain::LLM::Builder.new
                                         .with_system_message(system_prompt)
                                         .with_user_message("Xin hãy tạo tin nhắn phản hồi dựa trên bình luận của tôi.")
                                         .execute

    completion&.strip
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    nil
  end
end
