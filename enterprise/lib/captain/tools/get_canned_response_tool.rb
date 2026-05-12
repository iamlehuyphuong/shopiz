class Captain::Tools::GetCannedResponseTool < Captain::Tools::BasePublicTool
  description 'Search and retrieve a canned response (saved template) by its short code or keywords. Use this to quickly reply with standard, approved answers.'
  param :query, type: 'string', desc: 'The short code or keyword of the canned response (e.g., "hello", "pricing")', required: true

  def perform(tool_context, query:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    log_tool_usage('get_canned_response', { conversation_id: conversation.id, query: query })

    canned_responses = account_scoped(CannedResponse)
                       .where('short_code ILIKE :query OR content ILIKE :query', query: "%#{query}%")
                       .order_by_search(query)
                       .limit(3)

    return "No canned response found matching '#{query}'" if canned_responses.empty?

    results = canned_responses.map do |cr|
      "Short Code: #{cr.short_code}\nContent:\n#{cr.content}"
    end

    "Found #{results.size} matching canned response(s):\n\n#{results.join("\n---\n")}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to search canned responses'
  end

  private

  def permissions
    %w[conversation_manage]
  end
end
