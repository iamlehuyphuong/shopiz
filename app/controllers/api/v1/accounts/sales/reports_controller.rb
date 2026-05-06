class Api::V1::Accounts::Sales::ReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    from = params[:from].present? ? Time.zone.at(params[:from].to_i) : 7.days.ago.beginning_of_day
    to = params[:to].present? ? Time.zone.at(params[:to].to_i) : Time.current.end_of_day
    range = from..to

    render json: {
      metrics: build_metrics(range),
      chart_data: build_chart_data(range),
      orders_by_inbox: build_orders_by_inbox(range)
    }
  end

  def heatmap
    from = Time.zone.at(params[:from].to_i).beginning_of_hour
    to = Time.zone.at(params[:to].to_i).beginning_of_hour

    data_hash = orders_scope
                .where(created_at: from..to)
                .group("date_trunc('hour', created_at)")
                .count

    data = []
    current_time = from
    while current_time <= to
      data << { timestamp: current_time.to_i, value: data_hash[current_time] || 0 }
      current_time += 1.hour
    end

    render json: data
  end

  private

  def check_authorization
    authorize current_account, :sales_manage?
  end

  def orders_scope
    current_account.conversation_orders
  end

  def products_scope
    current_account.products
  end



  def build_metrics(range)
    current_orders = orders_scope.where(created_at: range)
    revenue_orders = current_orders.where(status: [:confirmed, :delivered])
    total_revenue = revenue_orders.sum(:total_amount).to_f
    total_orders = current_orders.count
    aov = total_orders.positive? ? (total_revenue / total_orders) : 0
    active_products = products_scope.where(status: :active).count

    # Previous period for comparison
    duration = range.last - range.first
    prev_range = (range.first - duration)..(range.first - 1.second)
    prev_orders = orders_scope.where(created_at: prev_range)
    prev_revenue_orders = prev_orders.where(status: [:confirmed, :delivered])
    prev_revenue = prev_revenue_orders.sum(:total_amount).to_f
    prev_total_orders = prev_orders.count
    prev_aov = prev_total_orders.positive? ? (prev_revenue / prev_total_orders) : 0

    {
      total_revenue: total_revenue,
      total_orders: total_orders,
      average_order_value: aov,
      active_products: active_products,
      previous: {
        total_revenue: prev_revenue,
        total_orders: prev_total_orders,
        average_order_value: prev_aov
      }
    }
  end

  def build_chart_data(range)
    orders_scope
      .where(created_at: range)
      .where(status: [:confirmed, :delivered])
      .group("DATE(created_at)")
      .select("DATE(created_at) as date, SUM(total_amount) as revenue, COUNT(*) as orders")
      .map { |r| { date: r.date.to_s, revenue: r.revenue.to_f, orders: r.orders } }
      .sort_by { |d| d[:date] }
  end

  def build_orders_by_inbox(range)
    orders = orders_scope.where(created_at: range)
                         .left_outer_joins(conversation: :inbox)
                         .group('inboxes.id', 'inboxes.name')
                         .count

    orders.map do |(inbox_id, inbox_name), count|
      {
        id: inbox_id || 0,
        name: inbox_name || 'No Inbox',
        count: count
      }
    end.sort_by { |d| -d[:count] }
  end
end
