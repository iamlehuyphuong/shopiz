require 'rails_helper'

RSpec.describe MaskingHelper, type: :helper do
  describe '.mask_email' do
    it 'masks regular emails correctly' do
      expect(described_class.mask_email('lethanhcong@gmail.com')).to eq('le***ng@gmail.com')
    end

    it 'masks short emails correctly (length <= 4)' do
      expect(described_class.mask_email('test@gmail.com')).to eq('t***t@gmail.com')
      expect(described_class.mask_email('abc@gmail.com')).to eq('a***c@gmail.com')
    end

    it 'masks very short emails correctly (length <= 2)' do
      expect(described_class.mask_email('ab@gmail.com')).to eq('a***b@gmail.com')
      expect(described_class.mask_email('a@gmail.com')).to eq('a***a@gmail.com')
    end

    it 'returns nil or original string if not valid' do
      expect(described_class.mask_email(nil)).to be_nil
      expect(described_class.mask_email('')).to eq('')
      expect(described_class.mask_email('invalidemail')).to eq('invalidemail')
    end
  end

  describe '.mask_phone' do
    it 'masks phone numbers correctly' do
      expect(described_class.mask_phone('+84123456789')).to eq('+84***789')
      expect(described_class.mask_phone('0981234567')).to eq('098***567')
    end

    it 'does not mask short phone numbers (length <= 6)' do
      expect(described_class.mask_phone('123456')).to eq('123456')
      expect(described_class.mask_phone('+123')).to eq('+123')
    end

    it 'returns nil or original string if blank' do
      expect(described_class.mask_phone(nil)).to be_nil
      expect(described_class.mask_phone('')).to eq('')
    end
  end
end
