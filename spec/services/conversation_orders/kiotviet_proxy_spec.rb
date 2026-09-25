# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrders::KiotvietProxy do
  let(:account) { create(:account) }
  let(:proxy) { described_class.new(account) }

  describe '#platform_name' do
    it 'returns Kiotviet' do
      expect(proxy.platform_name).to eq('Kiotviet')
    end
  end

  describe '#map_status' do
    it 'maps kiotviet statuses correctly' do
      expect(proxy.map_status(1)).to eq(:draft)
      expect(proxy.map_status(2)).to eq(:processing)
      expect(proxy.map_status(3)).to eq(:delivered)
      expect(proxy.map_status(4)).to eq(:cancelled)
      expect(proxy.map_status(999)).to be_nil # unknown fallback
    end
  end

  describe '#extract_raw_status' do
    it 'extracts status from response payload' do
      expect(proxy.extract_raw_status({ 'statusCode' => 3 })).to eq(3)
    end
  end

  describe '#extract_total' do
    it 'extracts total from response payload' do
      expect(proxy.extract_total({ 'totalPayment' => 150_000 })).to eq(150_000)
    end
  end

  describe '#extract_order_id' do
    it 'extracts id from response payload' do
      expect(proxy.extract_order_id({ 'id' => 12_345 })).to eq('12345')
    end
  end

  describe '#extract_error' do
    it 'extracts error message from response payload' do
      expect(proxy.extract_error({ 'errorMessage' => 'API Error' })).to eq('API Error')
      expect(proxy.extract_error({})).to include('failed for Kiotviet')
    end
  end
end
