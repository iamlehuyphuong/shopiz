class Captain::GenerateDailySummaryService < Captain::BaseTaskService
  pattr_initialize [:account!, :inbox_daily_summary!]

  CHUNK_TOKEN_LIMIT = 100_000

  def perform
    @since_time = inbox_daily_summary.last_run_at || Time.current.beginning_of_day
    conversations = fetch_conversations
    return if conversations.empty?
    
    chunks = build_chunks(conversations)
    return if chunks.empty?
    
    map_results = chunks.map do |chunk_text|
      map_chunk(chunk_text)
    end
    
    final_summary = reduce_summaries(map_results)
    
    if final_summary.present?
      DailySummaryMailer.with(
        inbox_daily_summary: inbox_daily_summary, 
        content: final_summary, 
        account: account
      ).report_email.deliver_later
      
      inbox_daily_summary.update(last_run_at: Time.current)
    end
  end

  private

  def event_name
    'daily_summary'
  end

  def instrumentation_metadata
    {
      inbox_count: inbox_daily_summary.inbox_ids.length
    }
  end

  def fetch_conversations
    return Conversation.none if inbox_daily_summary.inbox_ids.blank?

    Conversation.where(inbox_id: inbox_daily_summary.inbox_ids)
                .where('last_activity_at >= ?', @since_time)
  end
  
  def build_chunks(conversations)
    chunks = []
    current_chunk = ""
    
    conversations.each do |conv|
      text = conv.to_llm_text(include_contact_details: false, messages_since: @since_time)
      next if text.blank?
      
      if current_chunk.length + text.length > CHUNK_TOKEN_LIMIT && current_chunk.present?
        chunks << current_chunk
        current_chunk = ""
      end
      current_chunk += "\n---\n#{text}"
    end
    
    chunks << current_chunk if current_chunk.present?
    chunks
  end
  
  def map_chunk(chunk_text)
    system_prompt = <<~PROMPT
      You are an expert Customer Support Analyst.
      Your task is to analyze the provided customer support conversations, extract the most important information, and ignore conversational noise (like greetings and pleasantries).
      
      Specific analysis requirements from the manager:
      """
      #{inbox_daily_summary.summary_instruction.presence || 'Summarize key issues, customer feedback, and overall support status.'}
      """
      
      Present your preliminary analysis concisely and with a clear structure.
      IMPORTANT: You MUST write your entire response in #{account.locale_english_name}.
    PROMPT
    
    response = make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: chunk_text }
      ]
    )
    
    response[:message] || ""
  end
  
  def reduce_summaries(map_results)
    return map_results.first if map_results.length == 1
    
    combined_text = map_results.join("\n\n=== Next section ===\n\n")
    
    system_prompt = <<~PROMPT
      You are an expert Customer Support Analyst.
      I will provide you with a collection of preliminary summaries extracted from today's conversations.
      
      Your tasks:
      1. Merge these preliminary summaries into ONE single final report.
      2. Completely remove any duplicate information and combine similar points.
      3. Format the report using professional Markdown (use headings, bullet points, bold text, tables if necessary).
      4. The report must strictly adhere to the initial analysis goals below:
      
      Analysis goals:
      """
      #{inbox_daily_summary.reporting_instruction.presence || 'Summarize key issues, customer feedback, and overall support status.'}
      """
      
      Note: Do not provide any additional explanations. Return ONLY the content of the final report, as it will be sent directly to management.
      IMPORTANT: You MUST write your entire response in #{account.locale_english_name}.
    PROMPT
    
    response = make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: combined_text }
      ]
    )
    
    response[:message] || ""
  end
end
