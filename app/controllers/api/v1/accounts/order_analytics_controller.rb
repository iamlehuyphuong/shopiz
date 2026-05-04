# API endpoint for order analytics and reporting.
# GET /api/v1/accounts/:account_id/order_analytics
# Params: since, until, group_by (day/week/month)
class Api::V1::Accounts::OrderAnalyticsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def show
    orders = account_orders_scope

    render json: {
      summary: build_summary(orders),
      by_platform: build_platform_breakdown(orders),
      by_status: build_status_breakdown(orders),
      chart_data: build_chart_data(orders)
    }
  end

  private

  def check_authorization
    authorize :account, :report?
  end

  def account_orders_scope
    scope = Current.account.conversation_orders
    scope = scope.where(created_at: since_date..) if since_date
    scope = scope.where(created_at: ..until_date.end_of_day) if until_date
    scope
  end

  def since_date
    @since_date ||= Time.zone.parse(params[:since]) if params[:since].present?
  end

  def until_date
    @until_date ||= Time.zone.parse(params[:until]) if params[:until].present?
  end

  def group_by_period
    %w[day week month].include?(params[:group_by]) ? params[:group_by] : 'day'
  end

  def build_summary(orders)
    {
      total_orders: orders.count,
      total_revenue: orders.sum(:total_amount).to_f,
      avg_order_value: orders.average(:total_amount).to_f.round(2),
      orders_by_currency: orders.group(:currency).sum(:total_amount).transform_values(&:to_f)
    }
  end

  def build_platform_breakdown(orders)
    orders
      .where.not(external_source: [nil, ''])
      .group(:external_source)
      .select('external_source, COUNT(*) as order_count, SUM(total_amount) as revenue')
      .map { |r| { platform: r.external_source, order_count: r.order_count, revenue: r.revenue.to_f } }
  end

  def build_status_breakdown(orders)
    orders.group(:status).count.transform_keys { |k| ConversationOrder.statuses.key(k) || k }
  end

  def build_chart_data(orders)
    period_sql = "DATE_TRUNC('#{group_by_period}', created_at)"
    orders
      .group(Arel.sql(period_sql))
      .select(Arel.sql("#{period_sql} as period, COUNT(*) as order_count, SUM(total_amount) as revenue"))
      .order(Arel.sql(period_sql))
      .map { |r| { period: r.period, order_count: r.order_count, revenue: r.revenue.to_f } }
  end
end
