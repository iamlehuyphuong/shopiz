class Captain::Tools::Copilot::ListLabelsService < Captain::Tools::BaseTool
  def self.name
    'list_labels'
  end

  description 'List all available labels in the account for categorizing conversations'

  def execute
    labels = Label.where(account_id: @assistant.account_id).order(:title)
    return 'No labels found' unless labels.exists?

    <<~RESPONSE
      Total labels: #{labels.count}
      #{labels.map { |l| "- #{l.title}#{l.description.present? ? "(#{l.description})": ''}" }.join("\n")}
    RESPONSE
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end
