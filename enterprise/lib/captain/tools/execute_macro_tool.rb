class Captain::Tools::ExecuteMacroTool < Captain::Tools::BasePublicTool
  description 'Execute an automation macro on the current conversation. Macros can add labels, assign agents, resolve conversations, send emails, and perform other automated actions.'
  param :macro_name, type: 'string', desc: 'The exact name of the macro to execute', required: true

  def perform(tool_context, macro_name:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    log_tool_usage('execute_macro', { conversation_id: conversation.id, macro_name: macro_name })

    # Search for the macro by name in the account
    macro = account_scoped(Macro).find_by('name ILIKE ?', macro_name)
    return "Macro '#{macro_name}' not found. Please ensure the exact macro name is used." unless macro

    # Execute the macro asynchronously for the current conversation.
    # User is nil because it's executed by the AI (system).
    ::MacrosExecutionJob.perform_later(macro, conversation_ids: [conversation.display_id], user: nil)

    "Macro '#{macro.name}' has been successfully triggered for execution on this conversation."
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to execute macro'
  end

  private

  def permissions
    %w[conversation_manage]
  end
end
