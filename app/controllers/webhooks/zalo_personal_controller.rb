class Webhooks::ZaloPersonalController < ActionController::API
    def process_payload
      Rails.logger.info('Zalo Personal webhook received events')
      Webhooks::ZaloPersonalEventsJob.perform_later(
        params.to_unsafe_hash,
        signature: request.headers['X-ZEvent-Signature'],
        post_body: request.body.read
      )
      head :ok
    end
  end
