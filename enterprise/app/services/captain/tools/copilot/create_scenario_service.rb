class Captain::Tools::Copilot::CreateScenarioService < Captain::Tools::BaseTool
  def self.name
    'create_scenarios'
  end

  description <<~DESC
    FINAL STEP ONLY: Call this tool to bulk create multiple Captain Scenarios into the database.

    WORKFLOW REQUIREMENTS:
    1. Ask and extract information gradually from the user. Don't rush.
    2. Deconstruct the user's main intent into multiple specialized, interconnected scenarios (e.g., instead of 1 huge workflow, break it into "Identify Intent", "Handle Refund", "Handle Exchange", etc.) so they can support each other.
    3. You MUST present the designed list of scenarios (with titles and summarized instructions) to the user and clearly ask for their confirmation.
    4. ONLY call this tool AFTER the user explicitly agrees to add them to the database.

    Pass the scenarios as a JSON-encoded string.
  DESC

  param :scenarios_json, type: :string,
                         desc: 'A JSON string representing an array of objects. Example: "[{\"title\": \"A\", \"description\": \"B\", \"instruction\": \"C\"}]"'

  def execute(scenarios_json:)
    parsed_scenarios = parse_scenarios(scenarios_json)
    return 'Invalid JSON format for scenarios_json' unless parsed_scenarios.is_a?(Array)

    results = []
    ActiveRecord::Base.transaction do
      parsed_scenarios.each do |data|
        scenario = @assistant.scenarios.create!(
          account_id: @assistant.account_id,
          title: data['title'] || 'Untitled',
          description: data['description'] || 'No description',
          instruction: data['instruction'] || 'No instructions'
        )
        results << "Scenario ID #{scenario.id}: '#{scenario.title}'"
      end
    end

    "Successfully created the following scenarios:\n"+ results.join("\n")
  rescue JSON::ParserError
    'Failed to create scenarios: scenarios_json must be a valid JSON array.'
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create scenarios: #{e.message}"
  rescue StandardError => e
    "An error occurred while creating scenarios: #{e.message}"
  end

  def active?
    return false if @user.blank?

    account_user = AccountUser.find_by(account_id: @assistant.account_id, user_id: @user.id)
    return false if account_user.blank?

    account_user.administrator?
  end

  private

  def parse_scenarios(json_string)
    # LLMs sometimes wrap json in markdown block
    cleaned_str = json_string.to_s.gsub(/\A```json\s*/, '').gsub(/\s*```\z/, '').strip
    JSON.parse(cleaned_str)
  end
end
