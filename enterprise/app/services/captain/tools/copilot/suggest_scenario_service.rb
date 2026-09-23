class Captain::Tools::Copilot::SuggestScenarioService < Captain::Tools::BaseTool
  include Captain::Tools::Copilot::Concerns::ScenarioContext

  def self.name
    'suggest_scenario'
  end

  description <<~DESC
    Call this tool to suggest a single consultation scenario (kịch bản tư vấn) for the user to review.
    This tool should ONLY be used when you are asked to generate or suggest a scenario, typically inside the Scenario Creator interface.

    #{AGENT_TOOLS_DESCRIPTION}
  DESC

  param :title, type: :string, desc: 'Tên kịch bản ngắn gọn, súc tích', required: true
  param :description, type: :string, desc: 'Mô tả bối cảnh áp dụng kịch bản này', required: true
  param :instruction, type: :string, desc: 'Nội dung quy trình từng bước, định dạng Markdown (nhắc nhở AI sử dụng tool tương ứng)', required: true

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
