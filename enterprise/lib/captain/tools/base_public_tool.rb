require 'agents'

class Captain::Tools::BasePublicTool < Agents::Tool
  include Captain::Tools::Concerns::EcommerceIdentityMap

  def initialize(assistant)
    @assistant = assistant
    super()
  end

  module PermissionsEnforcer
    def perform(tool_context, **args)
      required_permissions = permissions
      if required_permissions.any?
        conversation = find_conversation(tool_context.state)
        user = tool_context.state[:user] || (conversation && conversation.assignee)

        # We enforce permissions if a user is acting, e.g. copilot or human agent context.
        # AI assistants typically bypass these if configured, but let's log and enforce if user exists.
        if user&.respond_to?(:permissions)
          missing_perms = required_permissions - user.permissions
          if missing_perms.any?
            Rails.logger.warn "Captain Tools: User #{user.id} missing permissions #{missing_perms.join(', ')} for #{self.class.name}"
            return "Missing required permissions: #{missing_perms.join(', ')}"
          end
        end
      end

      super
    end
  end

  prepend PermissionsEnforcer

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
    return ::Conversation.new(account_id: state[:account_id], id: 0, display_id: 0) if state[:source] == 'playground'

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
