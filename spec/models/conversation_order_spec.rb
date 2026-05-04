# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationOrder do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:contact).optional }
    it { is_expected.to have_many(:items).class_name('ConversationOrderItem').dependent(:destroy_async) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
  end

  describe 'enum' do
    it {
      expect(described_class.statuses).to eq(
        'draft' => 0, 'confirmed' => 1, 'processing' => 2,
        'shipped' => 3, 'delivered' => 4, 'cancelled' => 5
      )
    }
  end

  describe 'scopes' do
    describe '.ordered' do
      it 'returns orders in descending created_at order' do
        account = create(:account)
        conversation = create(:conversation, account: account)
        old_order = create(:conversation_order, account: account, conversation: conversation, created_at: 1.day.ago)
        new_order = create(:conversation_order, account: account, conversation: conversation, created_at: Time.current)

        expect(described_class.ordered).to eq([new_order, old_order])
      end
    end
  end

  describe '#calculate_total_amount' do
    it 'calculates total from items before save' do
      order = create(:conversation_order)
      order.items.create!(product_name: 'Product A', quantity: 2, unit_price: 100_000)
      order.items.create!(product_name: 'Product B', quantity: 1, unit_price: 50_000)
      order.save!

      expect(order.total_amount).to eq(250_000)
    end

    it 'excludes items marked for destruction' do
      order = create(:conversation_order)
      item1 = order.items.create!(product_name: 'Product A', quantity: 2, unit_price: 100_000)
      order.items.create!(product_name: 'Product B', quantity: 1, unit_price: 50_000)

      item1.mark_for_destruction
      order.save!

      expect(order.total_amount).to eq(50_000)
    end

    it 'returns 0 when no items' do
      order = create(:conversation_order)
      order.save!

      expect(order.total_amount).to eq(0)
    end
  end
end
