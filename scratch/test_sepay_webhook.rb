# frozen_string_literal: true
require_relative '../config/environment'

payload = {
  "id": 12345,
  "gateway": "MBBank",
  "transactionDate": "2023-10-10 10:10:10",
  "accountNumber": "123456789",
  "transferAmount": 2000,
  "content": "SHOPIZBIZAIMONTHLYA2T1713422345",
  "transferType": "in"
}.to_json

# We will just test the controller logic up to the perform call.
class MockRequest
  def raw_post
    @payload
  end
  def initialize(payload)
    @payload = payload
  end
  def headers
    { 'X-Secret-Key' => 'test_secret' }
  end
end

controller = Enterprise::Webhooks::SepayController.new
controller.request = MockRequest.new(payload)
# Stub verify_secret_key to return true
controller.define_singleton_method(:verify_secret_key) { true }

# Override render and head
controller.define_singleton_method(:render) { |*args| puts "Rendered: #{args.inspect}" }
controller.define_singleton_method(:head) { |*args| puts "Head: #{args.inspect}" }

# Stub perform
Enterprise::Billing::HandleSepayEventService.any_instance.stub(:perform) do |p|
  puts "Perform called with payload: #{p.inspect}"
end

puts "Testing standard payload:"
controller.process_payload
