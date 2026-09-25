class Captain::Tools::Copilot::SuggestScenarioService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::ScenarioContext

  def self.name
    'suggest_scenario'
  end

  description <<~DESC
    Call this tool to suggest a single consultation scenario (kịch bản tư vấn) for the user to review.

    [IMPORTANT] You MUST follow this 2-step process when designing a scenario:
    Step 1: WHEN THE USER REQUESTS A NEW SCENARIO
    - DO NOT CALL THIS TOOL. Simply reply with normal text to propose a "Scenario Title" and "Description" based on the request.
    - The "Description" is used by Captain AI to determine exactly WHEN to trigger this scenario in real operations. It MUST be written as a clear trigger condition (e.g., "Use this scenario when the customer asks for a price quote or needs product consultation").
    - Ask the user if they agree.
    Step 2: WHEN THE USER AGREES WITH THE TITLE AND DESCRIPTION
    - CALL THIS TOOL to generate the detailed scenario.
    - In the 'instruction' parameter, when referencing tools, you MUST use the Markdown link syntax: [tool_name](tool://tool_name). Ex: [search_products](tool://search_products). DO NOT use backticks (`).

    #{AGENT_TOOLS_DESCRIPTION}
  DESC

  param :title, type: :string, desc: 'Short and concise scenario title', required: true
  param :description, type: :string,
                      desc: 'Clear trigger condition helping Captain AI know exactly WHEN to use this scenario in real operations (e.g., "Use this when...")', required: true
  param :instruction, type: :string, desc: 'Step-by-step process content in Markdown format (remind AI to use the corresponding tools)',
                      required: true

  def execute(title:, description:, instruction:)
    {
      success: true,
      scenario: {
        title: title,
        description: description,
        instruction: instruction
      }
    }.to_json
  end

  def active?
    @user.present?
  end
end
