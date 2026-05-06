require 'rails_helper'

RSpec.describe Api::V1::PricingController, type: :request do
  describe 'GET /api/v1/pricing' do
    let!(:tier) { SubscriptionTier.create!(name_en: 'Tier 1 EN', name_vi: 'Tier 1 VI', visible: true) }
    let!(:hidden_tier) { SubscriptionTier.create!(name_en: 'Hidden EN', name_vi: 'Hidden VI', visible: false) }
    let!(:plan) { SubscriptionPlan.create!(subscription_tier: tier, visible: true, duration_days: 30, sku: 'plan-30') }
    let!(:addon) do
      AddonPackage.create!(visible: true, name: 'Addon', name_en: 'Addon EN', name_vi: 'Addon VI', addon_type: :ai_messages, quantity: 1,
                           sku: 'addon-1')
    end

    it 'returns visible pricing information' do
      get '/api/v1/pricing'

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body

      expect(json_response).to have_key('tiers')
      expect(json_response).to have_key('addons')

      expect(json_response['tiers'].length).to eq(1)
      expect(json_response['tiers'].first['id']).to eq(tier.id)
      expect(json_response['tiers'].first['plans'].length).to eq(1)
      expect(json_response['tiers'].first['plans'].first['id']).to eq(plan.id)

      expect(json_response['addons'].length).to eq(1)
      expect(json_response['addons'].first['id']).to eq(addon.id)
    end
  end
end
