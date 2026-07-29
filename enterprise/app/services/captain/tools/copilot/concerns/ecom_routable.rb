module Captain::Tools::Copilot::Concerns::EcomRoutable
  extend ActiveSupport::Concern

  private

  # Subclasses MUST override to provide { app_id => tool_class_name } mapping.
  def ecom_platform_tools
    raise NotImplementedError, "#{self.class} must implement ecom_platform_tools"
  end

  # Resolves the e-commerce platform app_id from the account settings.
  # Returns nil when no active integration is selected or if Shopiz native is used.
  def resolve_ecom_platform
    return nil unless @conversation

    account = @conversation.account
    return nil unless account

    active_platform = account.active_ecommerce_platform
    return nil if active_platform.blank? || active_platform == 'shopiz'

    active_platform
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
    return 'Integration is not fully configured or user lacks permission.' unless tool.active?

    tool.execute(**args)
  end
end
