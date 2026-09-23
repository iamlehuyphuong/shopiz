class Captain::Tools::GetOrderDetailTool < Captain::Tools::BasePublicTool
  include Captain::Tools::Concerns::EcomRoutable

  description 'Retrieve detailed information about a specific order by its order ID'

  param :order_id, type: 'string', desc: 'The specific order ID or display ID to look up', required: true

  def perform(tool_context, order_id:)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    # Route to ecom platform if inbox is linked
    platform = resolve_ecom_platform(tool_context)
    if platform
      args = build_search_orders_args(platform, order_id, nil)
      result = delegate_to_ecom_tool(platform, tool_context, **args)
      return result if result
    end

    # Fallback: delegate to SearchOrdersTool local DB search
    Captain::Tools::SearchOrdersTool.new(@assistant).perform(tool_context, order_id: order_id)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to get order detail'
  end

  private

  def permissions
    %w[conversation_manage]
  end

  # Map to the platform's search orders tool since it returns order details for a specific ID
  def ecom_platform_tools
    {
      'kiotviet' => 'Captain::Tools::Kiotviet::SearchOrdersTool',
      'sapo' => 'Captain::Tools::Sapo::SearchOrdersTool',
      'haravan' => 'Captain::Tools::Haravan::SearchOrdersTool',
      'shopify' => 'Captain::Tools::Shopify::SearchOrdersTool',
      'woocommerce' => 'Captain::Tools::Woocommerce::SearchOrdersTool',
      'nhanhvn' => 'Captain::Tools::Nhanhvn::SearchOrdersTool',
      'tiktok_shop' => 'Captain::Tools::TiktokShop::SearchOrdersTool'
    }.freeze
  end

  KWARG_PLATFORMS = %w[tiktok_shop].freeze

  def build_search_orders_args(platform, order_id, _phone_number)
    return { order_id: order_id } if KWARG_PLATFORMS.include?(platform)

    {}
  end
end
