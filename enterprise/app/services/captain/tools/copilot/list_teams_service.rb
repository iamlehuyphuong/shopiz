class Captain::Tools::Copilot::ListTeamsService < Captain::Tools::BaseTool
  def self.name
    'list_teams'
  end

  description 'List all teams in the account with their members'

  def execute
    teams = Team.where(account_id: @assistant.account_id).includes(:members)
    return 'No teams found' unless teams.exists?

    <<~RESPONSE
      Total teams: #{teams.count}
      #{teams.map { |t| format_team(t) }.join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage')
  end

  private

  def format_team(team)
    members_list = team.members.map { |m| "  - #{m.name} (ID: #{m.id})" }.join("\n")
    <<~TEAM.strip
      Team: #{team.name} (ID: #{team.id})
      Description: #{team.description.presence || 'N/A'}
      Auto-assign: #{team.allow_auto_assign}
      Members (#{team.members.count}):
      #{members_list.presence || '  (no members)'}
    TEAM
  end
end
