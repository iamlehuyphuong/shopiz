class Captain::Tools::Copilot::ListMacrosService < Captain::Tools::BaseTool
  def self.name
    'list_macros'
  end

  description 'List available macros (automated action sequences) that the agent can use'

  def execute
    macros = fetch_macros
    return 'No macros found' unless macros.exists?

    <<~RESPONSE
      Total macros: #{macros.count}
      #{macros.map { |m| format_macro(m) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end

  private

  def fetch_macros
    macros = Macro.where(account_id: @assistant.account_id).global
    macros = macros.or(Macro.where(account_id: @assistant.account_id, created_by_id: @user.id)) if @user.present?
    macros.order(:name)
  end

  def format_macro(macro)
    actions_summary = macro.actions.pluck('action_name').join(', ')
    <<~MACRO.strip
      Macro: #{macro.name} (ID: #{macro.id})
      Visibility: #{macro.visibility}
      Actions: #{actions_summary}
    MACRO
  end
end
