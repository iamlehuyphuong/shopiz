class Api::V1::Accounts::Sales::ReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    # Placeholder for actual reporting logic
    # In the future, this will aggregate orders from all synchronized platforms
    
    # Mock data for demonstration purposes
    render json: {
      metrics: {
        total_revenue: 15000000,
        total_orders: 125,
        average_order_value: 120000
      },
      chart_data: [
        { date: 6.days.ago.to_date.to_s, revenue: 1000000, orders: 10 },
        { date: 5.days.ago.to_date.to_s, revenue: 1500000, orders: 15 },
        { date: 4.days.ago.to_date.to_s, revenue: 2000000, orders: 20 },
        { date: 3.days.ago.to_date.to_s, revenue: 2500000, orders: 25 },
        { date: 2.days.ago.to_date.to_s, revenue: 3000000, orders: 22 },
        { date: 1.day.ago.to_date.to_s, revenue: 2000000, orders: 18 },
        { date: Date.current.to_s, revenue: 3000000, orders: 15 }
      ]
    }
  end

  private

  def check_authorization
    authorize current_account, :sales_manage?
  end
end
