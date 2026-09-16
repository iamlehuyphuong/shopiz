module Captain::Tools::Concerns::OrderMessageSendable
  extend ActiveSupport::Concern

  private

  def send_order_summary_message(conversation, order)
    locale = conversation.contact&.additional_attributes&.dig('locale') || conversation.account.locale || I18n.default_locale

    I18n.with_locale(locale) do
      content = format_order_summary(order)
      message_params = {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: 'outgoing',
        content: content,
        private: false
      }
      Messages::MessageBuilder.new(nil, conversation, message_params).perform
    end
  rescue StandardError => e
    Rails.logger.error("OrderMessageSendable: Failed to send order summary for order #{order.id}: #{e.message}")
  end

  def format_order_summary(order)
    lines = []
    lines << I18n.t('captain.tools.order_summary.header', order_id: order.id, default: "Order information ##{order.id}\n")

    lines << I18n.t('captain.tools.order_summary.product_list', default: 'Product list:')
    order.items.each_with_index do |item, index|
      item_total = item.quantity * item.unit_price
      lines << "  #{index + 1}. #{item.product_name} x #{item.quantity} - #{format_order_money(item.unit_price)}/item = #{format_order_money(item_total)}"
    end

    subtotal = order.items.sum { |i| i.quantity * i.unit_price }
    lines << "\n#{I18n.t('captain.tools.order_summary.subtotal', default: 'Subtotal')}: #{format_order_money(subtotal)}"
    if order.shipping_fee.to_f.positive?
      lines << "#{I18n.t('captain.tools.order_summary.shipping_fee',
                         default: 'Shipping fee')}: #{format_order_money(order.shipping_fee)}"
    end
    lines << "#{I18n.t('captain.tools.order_summary.tax', default: 'Tax')}: #{format_order_money(order.tax)}" if order.tax.to_f.positive?
    if order.discount_amount.to_f.positive?
      lines << "#{I18n.t('captain.tools.order_summary.discount',
                         default: 'Discount')}: -#{format_order_money(order.discount_amount)}"
    end
    lines << "#{I18n.t('captain.tools.order_summary.total', default: 'Total')}: #{format_order_money(order.total_amount)}"

    lines << "\n#{I18n.t('captain.tools.order_summary.customer', default: 'Customer')}: #{order.customer_name}" if order.customer_name.present?
    lines << "#{I18n.t('captain.tools.order_summary.phone', default: 'Phone')}: #{order.customer_phone}" if order.customer_phone.present?
    lines << "#{I18n.t('captain.tools.order_summary.address', default: 'Address')}: #{order.customer_address}" if order.customer_address.present?
    lines << "#{I18n.t('captain.tools.order_summary.note', default: 'Note')}: #{order.customer_note}" if order.customer_note.present?

    lines.join("\n")
  end

  def format_order_money(amount)
    return '0' if amount.blank?

    ActionController::Base.helpers.number_to_currency(amount, precision: 0, unit: 'đ', format: '%n %u')
  end
end
