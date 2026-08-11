class Captain::Conversation::CommentReplyService < Captain::BaseTaskService
  attr_accessor :customer_message, :post_id, :platform, :reply_type
  
  def initialize(account:, conversation:, customer_message:, post_id:, platform:, reply_type:)
    super(account: account, conversation_display_id: conversation.display_id)
    @customer_message = customer_message
    @post_id = post_id
    @platform = platform
    @reply_type = reply_type
  end

  def perform
    system_prompt = build_system_prompt
    response = make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: 'Please generate a reply message based on my comment.' }
      ]
    )
    
    return nil if response.is_a?(Hash) && response[:error].present?
    
    response[:message]&.strip
  end
  
  private
  
  def build_system_prompt
    channel = conversation.inbox.channel
    base_message = if reply_type == 'public'
                     channel.auto_public_reply_message
                   else
                     channel.auto_reply_message
                   end
    base_message = 'Hello, how can we help you?' if base_message.blank?
    
    reply_method = if platform == 'tiktok' || reply_type == 'public'
                     'public comment'
                   else
                     'private direct message (DM)'
                   end
                   
    contact_name = conversation.contact.name
                   
    <<~PROMPT
      You are a customer service assistant for our #{platform.capitalize} page.
      Your task: Reply to the customer's comment via a #{reply_method}.

      Below is the default reply template configured for our store:
      "#{base_message}"

      Please rewrite this default template to be natural, friendly, and contextually relevant to the customer's comment. 
      You MUST maintain the core meaning and intent of the default template.

      Guidelines:
      - Include the customer's name ("#{contact_name}") in the reply to make it more friendly and personalized (e.g., mention them).
      - **CRITICAL**: The final reply MUST be written in the same language that the customer used in their comment.
      - Do NOT include any explanations, formatting, or extra text. Return ONLY the final message content to be sent to the customer.

      Customer Information:
      Customer Name: #{contact_name}
      Post ID: #{post_id}
      Customer's Comment: "#{customer_message}"
    PROMPT
  end

  def event_name
    'comment_reply_generation'
  end
end
