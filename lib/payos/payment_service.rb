class Payos::PaymentService
  def initialize(client: Payos::Client.new)
    @client = client
  end

  def create_order(amount:, order_code:, return_url:, cancel_url:, description:)
    payload = {
      orderCode: order_code,
      amount: amount,
      description: description,
      returnUrl: return_url,
      cancelUrl: cancel_url
    }

    @client.create_payment_link(payload)
  end

  def verify_callback(params)
    @client.verify_signature?(params)
  end
end
