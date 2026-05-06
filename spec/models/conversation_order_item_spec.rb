# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrderItem do
  describe 'associations' do
    it { is_expected.to belong_to(:conversation_order) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:product_name) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:unit_price) }
    it { is_expected.to validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
  end

  describe '#calculate_total_price' do
    it 'calculates total_price from quantity and unit_price before save' do
      order = create(:conversation_order)
      item = order.items.create!(product_name: 'Test Product', quantity: 3, unit_price: 50_000)

      expect(item.total_price).to eq(150_000)
    end

    it 'updates total_price when quantity changes' do
      order = create(:conversation_order)
      item = order.items.create!(product_name: 'Test Product', quantity: 2, unit_price: 100_000)
      item.update!(quantity: 5)

      expect(item.total_price).to eq(500_000)
    end
  end
end
