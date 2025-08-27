class Enterprise::Webhooks::PolarController < ActionController::API
  def process_payload
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers['Stripe-Signature']

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      print "Xin chào thế giới"
      plans = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')&.value
      plans ||= InstallationConfig.create!(name: 'CHATWOOT_CLOUD_PLANS', value: [{"name":"Trial","product_id":["3f2c6699-19ad-46ed-b6d6-5a0d9faa20aa","3f2c6699-19ad-46ed-b6d6-5a0d9faa20aa","3f2c6699-19ad-46ed-b6d6-5a0d9faa20aa"],"price_ids":["29cfee9c-5fad-4358-a4a2-ebe917837b02","29cfee9c-5fad-4358-a4a2-ebe917837b02","29cfee9c-5fad-4358-a4a2-ebe917837b02"]},{"name":"Startups","product_id":["f49e3c5e-3cf6-409c-8c0f-6cdf6c55f073","b1817a9c-9a7c-4300-8c4b-7b9d396ca519","ea8dacf8-1276-421b-b0c3-698478474f54"],"price_ids":["63e8aa04-71c0-46cf-bbc3-be5e153cb89b","a567a1ed-b98f-4ef8-abc2-84dc29212427","bbb6e3d0-32a3-46e4-bd77-59d9ea18240d"]},{"name":"Pro","product_id":["1b9b8487-d50c-464b-8fb6-29fdabd273fb","7fa49366-6a77-4b57-b722-51e8f09a2c50","e192ded4-8387-4c68-bd5b-d9fcb358597e"],"price_ids":["c36e0402-4f68-4efd-9e3a-48cfab9b0405","d9107040-e438-4329-8610-23825ed777e5","c827666a-ad66-456d-9516-165d5823d4f7"]},{"name":"Business","product_id":["7f2765e9-bfb3-4ffa-91cc-2a10b491d7c5","6056fe81-5d8e-4939-b261-db51b4d24a53","8d8bdc72-6b08-4833-b9a3-1c89a50057e1"],"price_ids":["ebc17632-8de6-4eb4-bdd7-44807a883a85","27649392-d1fc-4efa-a412-1d4c1b455734","d949647c-2f5b-4fb4-91a5-4e82555f2aac"]},{"name":"Enterprise","product_id":["34a6a635-b9bf-44ed-967c-83b8c79a47ac","34a6a635-b9bf-44ed-967c-83b8c79a47ac","34a6a635-b9bf-44ed-967c-83b8c79a47ac"],"price_ids":["58357c28-530f-4442-8be5-bad590f2314b","58357c28-530f-4442-8be5-bad590f2314b","58357c28-530f-4442-8be5-bad590f2314b"]}]).value
      plans
    # If we fail to verify the signature, then something was wrong with the request
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      # Invalid payload
      head :bad_request
      return
    end

    # We've successfully processed the event without blowing up
    head :ok
  end
end
