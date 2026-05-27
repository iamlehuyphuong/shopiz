class Captain::Tools::Copilot::ListAutomationRulesService < Captain::Tools::BaseTool
  def self.name
    'list_automation_rules'
  end

  description 'List automation rules to understand what automated workflows are active'
  param :active_only, type: :boolean, desc: 'If true, only show active rules (default: true)', required: false

  def execute(active_only: true)
    rules = AutomationRule.where(account_id: @assistant.account_id)
    rules = rules.active if active_only
    rules = rules.order(:name)
    return 'No automation rules found' unless rules.exists?

    <<~RESPONSE
      Total automation rules: #{rules.count}
      #{rules.map { |r| format_rule(r) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('conversation_manage')
  end

  private

  def format_rule(rule)
    actions_summary = rule.actions.map { |a| a['action_name'] }.join(', ')
    conditions_summary = rule.conditions.map { |c| c['attribute_key'] }.join(', ')
    <<~RULE.strip
      Rule: #{rule.name} (ID: #{rule.id})
      Status: #{rule.active ? 'Active' : 'Inactive'}
      Event: #{rule.event_name}
      Conditions: #{conditions_summary}
      Actions: #{actions_summary}
      #{rule.description.present? ? "Description: #{rule.description.truncate(200)}": ''}
    RULE
  end
end
