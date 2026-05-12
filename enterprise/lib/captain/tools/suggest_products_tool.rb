# Generic router tool: Suggest upsell/cross-sell products.
# Auto-delegates to the platform-specific suggest tool based on the
# conversation inbox's e-commerce integration.
# Falls back with an informational message when no ecom is linked
# (there is no local DB suggest logic).
class Captain::Tools::SuggestProductsTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::EcomRoutable

  description 'Suggest upsell and cross-sell products based on the current product selection and conversation context'

  param :product_identifier, type: 'string', desc: 'Product ID or code to base suggestions on', required: true
  param :context, type: 'string', desc: 'What the customer is looking for', required: false

  # KiotViet & Nhanh.vn use product_code; all others use product_id
  CODE_BASED_PLATFORMS = %w[kiotviet nhanhvn].freeze

  def perform(tool_context, product_identifier:, context: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    platform = resolve_ecom_platform(tool_context)
    if platform
      args = build_platform_args(platform, product_identifier, context)
      result = delegate_to_ecom_tool(platform, tool_context, **args)
      return result if result
    end

    'Product suggestions require an e-commerce integration. Please connect your store in Inbox settings.'
  end

  private

  def permissions
    %w[conversation_manage]
  end

  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::KiotvietSuggestProductsTool',
      'sapo' => 'Captain::Tools::SapoSuggestProductsTool',
      'haravan' => 'Captain::Tools::HaravanSuggestProductsTool',
      'shopify' => 'Captain::Tools::ShopifySuggestProductsTool',
      'woocommerce' => 'Captain::Tools::WoocommerceSuggestProductsTool',
      'nhanhvn' => 'Captain::Tools::NhanhvnSuggestProductsTool',
      'tiktok_shop' => 'Captain::Tools::TiktokShopSuggestProductsTool'
    }.freeze
  end

  def build_platform_args(platform, identifier, context)
    if CODE_BASED_PLATFORMS.include?(platform)
      { product_code: identifier, context: context }.compact
    else
      { product_id: identifier, context: context }.compact
    end
  end
end
