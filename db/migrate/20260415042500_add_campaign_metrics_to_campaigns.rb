class AddCampaignMetricsToCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :campaign_metrics, :jsonb, default: {}
  end
end
