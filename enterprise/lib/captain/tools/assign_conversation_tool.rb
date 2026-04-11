class Captain::Tools::AssignConversationTool < Captain::Tools::BasePublicTool
  description "Assign a conversation to the most suitable team based on the issue description. " \
              "The system will automatically find the best matching team by comparing the issue with team descriptions, " \
              "then auto-assign an available agent from that team using round-robin policy."
  param :issue_description, type: 'string', desc: 'Brief description of the customer issue to match with the right team'
  param :team_name, type: 'string', desc: 'Exact team name to assign to (optional - if provided, skips smart matching)', required: false

  def perform(tool_context, issue_description:, team_name: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    team = team_name.present? ? find_team_by_name(team_name) : find_best_matching_team(issue_description)
    return "No matching team found for: #{issue_description}" unless team

    conversation.update!(team_id: team.id)

    log_tool_usage('assign_conversation', {
                     conversation_id: conversation.id,
                     team_id: team.id,
                     team_name: team.name,
                     issue_description: issue_description
                   })

    assignee_info = conversation.reload.assignee
    if assignee_info
      "Conversation ##{conversation.display_id} assigned to team '#{team.name}' → agent '#{assignee_info.name}' (auto-assigned)"
    else
      "Conversation ##{conversation.display_id} assigned to team '#{team.name}' (no agent auto-assigned — team members may be offline or at capacity)"
    end
  end

  private

  def find_team_by_name(name)
    account_scoped(Team).find_by('LOWER(name) = ?', name.strip.downcase)
  end

  def find_best_matching_team(issue_description)
    teams = account_scoped(Team).where.not(description: [nil, ''])
    return account_scoped(Team).first if teams.empty?

    issue_words = normalize_words(issue_description)
    best_team = nil
    best_score = 0

    teams.find_each do |team|
      team_words = normalize_words("#{team.name} #{team.description}")
      score = (issue_words & team_words).size
      if score > best_score
        best_score = score
        best_team = team
      end
    end

    best_team || account_scoped(Team).first
  end

  def normalize_words(text)
    text.downcase.gsub(/[^a-z0-9\sàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ]/, '')
        .split(/\s+/)
        .reject { |w| w.length < 2 }
        .uniq
  end

  def permissions
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
  end
end
