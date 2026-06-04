# Shared concern for routing tool calls to the correct e-commerce platform.
# Include in any "base" tool that should auto-delegate to a platform-specific
# tool when the conversation's inbox is linked to an e-commerce integration.
#
# Usage:
#   include Captain::Tools::Concerns::EcomRoutable
#
#   # Define the mapping in the subclass:
#   def ecom_platform_tools
#     { 'kiotviet' => 'Captain::Tools::KiotvietGetProductTool', ... }.freeze
#   end
#
#   # In perform:
#   platform = resolve_ecom_platform(tool_context)
#   if platform
#     result = delegate_to_ecom_tool(platform, tool_context, query: query)
#     return result if result
#   end
#   # ... fallback to local DB ...
module Captain::Tools::Concerns::EcomRoutable
  extend ActiveSupport::Concern

  private

  # Subclasses MUST override to provide { app_id => tool_class_name } mapping.
  def ecom_platform_tools
    raise NotImplementedError, "#{self.class} must implement ecom_platform_tools"
  end

  # Resolves the e-commerce platform app_id from the account settings.
  # Returns nil when no active integration is selected or if Shopiz native is used.
  def resolve_ecom_platform(tool_context)
    conversation = find_conversation(tool_context.state)
    return nil unless conversation

    account = conversation.account
    return nil unless account

    active_platform = account.active_ecommerce_platform
    return nil if active_platform.blank? || active_platform == 'shopiz'

    active_platform
  end

  # Instantiates the platform-specific tool and delegates the perform call.
  # Returns nil if the platform has no matching tool (caller should fallback).
  def delegate_to_ecom_tool(platform, tool_context, **args)
    tool_class_name = ecom_platform_tools[platform]
    return nil unless tool_class_name

    tool_class = tool_class_name.safe_constantize
    return nil unless tool_class

    log_tool_usage("ecom_route:#{platform}", args)
    tool_class.new(@assistant).perform(tool_context, **args)
  end
end
