# Generic router tool: Create a draft order.
# Auto-delegates to the platform-specific create order draft tool based on
# the conversation inbox's e-commerce integration.
# Falls back with an informational message when no ecom is linked
# (there is no local DB create-order-draft logic).
class Captain::Tools::CreateOrderDraftTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::EcomRoutable

  description 'Create a draft order with products for the current contact. ' \
              'The order is saved as a draft for agent review.'

  param :product_identifiers, type: 'string', desc: 'Comma-separated product IDs or codes (e.g. "123,456")', required: true
  param :quantities, type: 'string', desc: 'Comma-separated quantities matching each product (e.g. "2,1")', required: true
  param :customer_note, type: 'string', desc: 'Optional note from the customer', required: false

  # KiotViet & Nhanh.vn use product_codes; all others use product_ids
  CODE_BASED_PLATFORMS = %w[kiotviet nhanhvn].freeze

  def perform(tool_context, product_identifiers:, quantities:, customer_note: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    platform = resolve_ecom_platform(tool_context)
    if platform
      args = build_platform_args(platform, product_identifiers, quantities, customer_note)
      result = delegate_to_ecom_tool(platform, tool_context, **args)
      return result if result
    end

    'Order creation requires an e-commerce integration. Please connect your store in Inbox settings.'
  end

  private

  def permissions
    %w[conversation_manage]
  end

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::KiotvietCreateOrderDraftTool',
      'sapo' => 'Captain::Tools::SapoCreateOrderDraftTool',
      'haravan' => 'Captain::Tools::HaravanCreateOrderDraftTool',
      'shopify' => 'Captain::Tools::ShopifyCreateOrderDraftTool',
      'woocommerce' => 'Captain::Tools::WoocommerceCreateOrderDraftTool',
      'nhanhvn' => 'Captain::Tools::NhanhvnCreateOrderDraftTool'
      # TikTok Shop does not support create_order_draft
    }.freeze
  end

  def build_platform_args(platform, identifiers, quantities, note)
    base = { quantities: quantities, customer_note: note }.compact
    if CODE_BASED_PLATFORMS.include?(platform)
      base.merge(product_codes: identifiers)
    else
      base.merge(product_ids: identifiers)
    end
  end
end
