# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::Accounts::OrderAnalytics', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/order_analytics' do
    before do
      order1 = create(:conversation_order, :delivered, account: account, external_source: 'kiotviet', created_at: 1.day.ago)
      order1.update_columns(total_amount: 100)
      order2 = create(:conversation_order, :processing, account: account, external_source: 'shopify', created_at: 2.days.ago)
      order2.update_columns(total_amount: 50)
    end

    context 'when user is administrator' do
      it 'returns analytics data' do
        get api_v2_account_order_analytics_url(account_id: account.id),
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['summary']['total_orders']).to eq(2)
        expect(json_response['summary']['total_revenue'].to_f).to eq(150.0)
        expect(json_response['summary']['avg_order_value'].to_f).to eq(75.0)

        expect(json_response['by_platform'].length).to eq(2)
        expect(json_response['by_status'].keys).to contain_exactly('delivered', 'processing')
      end

      it 'filters by date range' do
        get api_v2_account_order_analytics_url(account_id: account.id),
            params: { since: 1.day.ago.beginning_of_day.iso8601 },
            headers: admin.create_new_auth_token,
            as: :json

        json_response = JSON.parse(response.body)
        expect(json_response['summary']['total_orders']).to eq(1) # Only the 1.day.ago order
      end
    end

    context 'when user is agent without permissions' do
      it 'returns unauthorized' do
        # NOTE: Depending on check_sales_permission implementation, this might return success if agents are allowed,
        # or unauthorized/forbidden if restricted. We assume admin is required or agent has no custom_role with report_manage.
        get api_v2_account_order_analytics_url(account_id: account.id),
            headers: agent.create_new_auth_token,
            as: :json

        # Update expectation based on actual authorization policy for reports/analytics in Flowify
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
