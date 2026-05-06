class Captain::Tools::ExecuteMacroService < Captain::Tools::BaseTool
  def self.name
    'execute_macro'
  end

  description 'Execute a predefined macro (automation rule) on the current conversation to perform actions like sending messages, assigning labels, or closing the conversation.'

  param :macro_name, type: :string, desc: 'The name or a part of the name of the macro that you want to execute.', required: true

  def initialize(assistant, user: nil, conversation: nil)
    super(assistant, user: user)
    @conversation = conversation
  end

  def execute(macro_name:)
    return 'Execution failed: No conversation context found.' if @conversation.blank?

    macros = find_macros
    return 'Execution failed: No macros found in this account.' unless macros.exists?

    macro = search_best_macro(macros, macro_name)
    return "Execution failed: No macro matched the given name '#{macro_name}'." if macro.blank?

    ::Macros::ExecutionService.new(macro, @conversation, @user).perform

    "Successfully executed macro: '#{macro.name}'. Actions applied to the conversation."
  rescue StandardError => e
    "Execution failed with error: #{e.message}"
  end

  def active?
    true
  end

  private

  def find_macros
    macros = Macro.where(account_id: @assistant.account_id).global
    # In Assistant Chat, @user is nil, so we only fetch global macros or macros that might be specific.
    macros = macros.or(Macro.where(account_id: @assistant.account_id, created_by_id: @user.id)) if @user.present?
    macros
  end

  def search_best_macro(macros, search_text)
    sanitized_text = search_text.to_s.strip
    return nil if sanitized_text.blank?

    # 1. Try exact exact match (case-insensitive)
    exact_match = macros.find_by('name ILIKE ?', sanitized_text)
    return exact_match if exact_match.present?

    # 2. Try partial match
    partial_match = macros.find_by('name ILIKE ?', "%#{sanitized_text}%")
    return partial_match if partial_match.present?

    # 3. Try fallback to finding if there are matching words
    words = sanitized_text.split.select { |w| w.length > 2 }
    if words.present?
      conditions = words.map { 'name ILIKE ?' }.join(' AND ')
      values = words.map { |w| "%#{w}%" }
      word_match = macros.where(conditions, *values).first
      return word_match if word_match.present?
    end

    nil
  end
end
