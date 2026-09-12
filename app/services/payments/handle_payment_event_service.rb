module Payments
  class HandlePaymentEventService
    def initialize(order:, event_type:)
      @order = order
      @event_type = event_type
      @conversation = order.conversation
    end

    def perform
      return if @order.blank?

      case @event_type
      when 'success'
        handle_success
      when 'failed', 'expired'
        handle_failure
      end
    end

    private

    def handle_success
      # Avoid duplicate processing
      return if @order.paid?

      @order.update!(
        payment_status: 'paid',
        status: 'confirmed'
      )

      return if @conversation.blank?

      assistant = @conversation.inbox.try(:captain_assistant)
      if assistant.present? && @conversation.pending?
        # Trigger Captain AI to respond to the webhook event
        Captain::Conversation::SystemEventBuilderJob.perform_later(
          @conversation,
          assistant,
          "The payment for order ##{@order.id} has been marked as 'SUCCESS' and the order is now 'confirmed'."
        )
      else
        # Fallback to system message
        message_params = {
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          message_type: 'outgoing',
          content: I18n.t('conversation_orders.payment.success',
                          default: "Cảm ơn bạn! Thanh toán cho đơn hàng ##{@order.id} đã thành công. Chúng tôi đang xử lý đơn hàng của bạn."),
          private: false
        }
        Messages::MessageBuilder.new(nil, @conversation, message_params).perform
      end
    end

    def handle_failure
      # Avoid overwriting a paid status
      return if @order.paid?

      @order.update!(payment_status: @event_type)

      return if @conversation.blank?

      assistant = @conversation.inbox.try(:captain_assistant)
      if assistant.present? && @conversation.pending?
        event_reason = @event_type == 'expired' ? 'EXPIRED' : 'FAILED'
        Captain::Conversation::SystemEventBuilderJob.perform_later(
          @conversation,
          assistant,
          "The payment for order ##{@order.id} has been marked as '#{event_reason}'."
        )
      else
        # Send failure/expired message to re-engage the customer for Agent/Captain AI
        content = if @event_type == 'expired'
                    I18n.t('conversation_orders.payment.expired',
                           default: 'Dạ em thấy anh/chị chưa thanh toán được, không biết anh/chị có gặp khó khăn gì với ứng dụng ngân hàng không ạ để em/AI hỗ trợ tiếp?')
                  else
                    I18n.t('conversation_orders.payment.failed',
                           default: 'Dạ thanh toán của mình vừa bị lỗi, anh/chị có cần em hỗ trợ kiểm tra lại không ạ?')
                  end

        message_params = {
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          message_type: 'outgoing',
          content: content,
          private: false
        }
        Messages::MessageBuilder.new(nil, @conversation, message_params).perform
      end
    end
  end
end
