class Captain::Tools::SearchDocumentationService < Captain::Tools::BaseTool
  MAX_CALLS = 2

  def self.name
    'search_documentation'
  end
  description 'Search and retrieve documentation from knowledge base. Do NOT call more than twice per conversation.'

  param :query, desc: 'Search Query', required: true

  def execute(query:)
    @call_count = (@call_count || 0) + 1

    if @call_count > MAX_CALLS
      return 'Maximum search attempts reached. No additional relevant documentation found. ' \
             'Please respond based on the information already retrieved, or let the user know ' \
             'the information is not available in the knowledge base.'
    end

    Rails.logger.info { "#{self.class.name}: #{query} (call ##{@call_count})" }

    translated_query = Captain::Llm::TranslateQueryService
                       .new(account: assistant.account)
                       .translate(query, target_language: assistant.account.locale_english_name)

    responses = assistant.responses.approved.search(translated_query)

    if responses.empty?
      return 'No FAQs found for the given query. Do not retry with a different query. ' \
             'Respond to the user based on what you know, or suggest they speak with a support agent.'
    end

    responses.map { |response| format_response(response) }.join
  end

  private

  def format_response(response)
    formatted_response = "
        Question: #{response.question}
        Answer: #{response.answer}
        "
    if response.documentable.present? && response.documentable.try(:external_link)
      formatted_response += "
          Source: #{response.documentable.external_link}
          "
    end

    formatted_response
  end
end
