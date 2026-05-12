module Captain::Tools::Copilot::Concerns::EcomRoutable
  extend ActiveSupport::Concern

  private

  # Subclasses MUST override to provide { app_id => tool_class_name } mapping.
  def ecom_platform_tools
    raise NotImplementedError, "#{self.class} must implement ecom_platform_tools"
  end

  # Resolves the e-commerce platform app_id from the conversation's inbox.
  # Returns nil when the inbox has no e-commerce integration.
  def resolve_ecom_platform
    return nil unless @conversation

    inbox = @conversation.inbox
    return nil unless inbox

    hook = inbox.effective_ecommerce_hook
    hook&.app_id
  end

  # Instantiates the platform-specific tool and delegates the execute call.
  # Returns a string error if the platform has no matching tool or no integration is found.
  def delegate_to_ecom_tool(**args)
    platform = resolve_ecom_platform
    return 'No e-commerce integration found for this conversation.' unless platform

    tool_class_name = ecom_platform_tools[platform]
    return "This operation is not supported for #{platform} integration." unless tool_class_name

    tool_class = tool_class_name.safe_constantize
    return "Tool class #{tool_class_name} not found." unless tool_class

    tool = tool_class.new(@assistant, user: @user, conversation: @conversation)
    
    # If the tool is not active for the current user/assistant, we should notify the AI
    return "Integration is not fully configured or user lacks permission." unless tool.active?

    tool.execute(**args)
  end
end
