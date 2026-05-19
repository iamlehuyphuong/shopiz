require 'agents'

class Captain::Tools::BasePublicTool < Agents::Tool
  def initialize(assistant)
    @assistant = assistant
    super()
  end

  def active?
    # Public tools are always active
    true
  end

  def permissions
    # Override in subclasses to specify required permissions
    # Returns empty array for public tools (no permissions required)
    []
  end

  private

  def account_scoped(model_class)
    model_class.where(account_id: @assistant.account_id)
  end

  def find_conversation(state)
    if state[:source] == 'playground'
      return ::Conversation.new(account_id: state[:account_id], id: 0, display_id: 0)
    end

    conv_data = state[:conversation]
    return nil unless conv_data

    conversation_id = conv_data.is_a?(Hash) ? conv_data[:id] : conv_data.id
    account_scoped(::Conversation).find_by(id: conversation_id)
  end

  def find_contact(state)
    contact_data = state[:contact]
    return nil unless contact_data

    contact_id = contact_data.is_a?(Hash) ? contact_data[:id] : contact_data.id
    account_scoped(::Contact).find_by(id: contact_id)
  end

  def log_tool_usage(action, details = {})
    Rails.logger.info do
      "#{self.class.name}: #{action} for assistant #{@assistant&.id} - #{details.inspect}"
    end
  end
end
