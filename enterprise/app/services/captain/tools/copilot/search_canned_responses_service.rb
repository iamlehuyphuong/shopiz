class Captain::Tools::Copilot::SearchCannedResponsesService < Captain::Tools::BaseTool
  def self.name
    'search_canned_responses'
  end

  description 'Search canned responses (quick reply templates) by short code or content'
  param :query, type: :string, desc: 'Search by short code or content (partial match)', required: false

  def execute(query: nil)
    responses = CannedResponse.where(account_id: @assistant.account_id)
    responses = responses.order_by_search(query) if query.present?
    responses = responses.order(:short_code) if query.blank?
    return 'No canned responses found' unless responses.exists?

    total_count = responses.count
    responses = responses.limit(50)

    <<~RESPONSE
      #{total_count > 50 ? "Found #{total_count} canned responses (showing first 50)": "Total canned responses: #{total_count}"}
      #{responses.map { |r| format_response(r) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end

  private

  def format_response(canned)
    <<~CR.strip
      Short code: /#{canned.short_code}
      Content: #{canned.content.truncate(300)}
    CR
  end
end
