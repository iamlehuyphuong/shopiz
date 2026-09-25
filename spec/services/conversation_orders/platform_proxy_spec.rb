# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrders::PlatformProxy do
  let(:account) { create(:account) }
  let(:proxy) { described_class.new(account) }

  describe 'abstract methods' do
    it 'raises NotImplementedError for create_order' do
      expect { proxy.create_order({}) }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError for fetch_order' do
      expect { proxy.fetch_order('123') }.to raise_error(NotImplementedError)
    end
  end

  describe '#extract_order_id' do
    it 'extracts id if present' do
      expect(proxy.extract_order_id({ 'id' => 1 })).to eq('1')
    end
  end

  describe '#extract_error' do
    it 'extracts error message' do
      expect(proxy.extract_error({ 'message' => 'Error' })).to eq('Error')
    end
  end
end
