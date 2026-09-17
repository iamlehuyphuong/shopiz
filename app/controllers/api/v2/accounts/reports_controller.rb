class Api::V2::Accounts::ReportsController < Api::V1::Accounts::BaseController
  include Api::V2::Accounts::ReportsHelper
  include Api::V2::Accounts::HeatmapHelper

  before_action :check_authorization

  def index
    builder = V2::Reports::Conversations::ReportBuilder.new(Current.account, report_params)
    data = builder.timeseries
    render json: data
  end

  def summary
    render json: build_summary(:summary)
  end

  def bot_summary
    render json: build_summary(:bot_summary)
  end

  def agents
    @report_data = generate_agents_report
    headers = [
      I18n.t('reports.agent_csv.agent_name'),
      I18n.t('reports.agent_csv.conversations_count'),
      I18n.t('reports.agent_csv.avg_first_response_time'),
      I18n.t('reports.agent_csv.avg_resolution_time'),
      I18n.t('reports.agent_csv.avg_customer_waiting_time'),
      I18n.t('reports.agent_csv.resolution_count')
    ]
    generate_xlsx('agents_report', headers, @report_data)
  end

  def inboxes
    @report_data = generate_inboxes_report
    headers = [
      I18n.t('reports.inbox_csv.inbox_name'),
      I18n.t('reports.inbox_csv.inbox_type'),
      I18n.t('reports.inbox_csv.conversations_count'),
      I18n.t('reports.inbox_csv.avg_first_response_time'),
      I18n.t('reports.inbox_csv.avg_resolution_time')
    ]
    generate_xlsx('inboxes_report', headers, @report_data)
  end

  def labels
    @report_data = generate_labels_report
    headers = [
      I18n.t('reports.label_csv.label_title'),
      I18n.t('reports.label_csv.conversations_count'),
      I18n.t('reports.label_csv.avg_first_response_time'),
      I18n.t('reports.label_csv.avg_resolution_time'),
      I18n.t('reports.label_csv.avg_reply_time'),
      I18n.t('reports.label_csv.resolution_count')
    ]
    generate_xlsx('labels_report', headers, @report_data)
  end

  def teams
    @report_data = generate_teams_report
    headers = [
      I18n.t('reports.team_csv.team_name'),
      I18n.t('reports.team_csv.conversations_count'),
      I18n.t('reports.team_csv.avg_first_response_time'),
      I18n.t('reports.team_csv.avg_resolution_time'),
      I18n.t('reports.team_csv.avg_customer_waiting_time'),
      I18n.t('reports.team_csv.resolution_count')
    ]
    generate_xlsx('teams_report', headers, @report_data)
  end

  def conversations_summary
    @report_data = generate_conversations_report
    headers = [
      I18n.t('reports.conversation_csv.conversations_count'),
      I18n.t('reports.conversation_csv.incoming_messages_count'),
      I18n.t('reports.conversation_csv.outgoing_messages_count'),
      I18n.t('reports.conversation_csv.avg_first_response_time'),
      I18n.t('reports.conversation_csv.avg_resolution_time'),
      I18n.t('reports.conversation_csv.resolution_count'),
      I18n.t('reports.conversation_csv.avg_customer_waiting_time')
    ]
    generate_xlsx('conversations_summary_report', headers, @report_data)
  end

  def conversation_traffic
    @report_data = generate_conversations_heatmap_report
    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]

    generate_xlsx('conversation_traffic_reports', nil, @report_data, is_traffic: true)
  end

  def conversations
    return head :unprocessable_entity if params[:type].blank?

    render json: conversation_metrics
  end

  def bot_metrics
    bot_metrics = V2::Reports::BotMetricsBuilder.new(Current.account, params).metrics
    render json: bot_metrics
  end

  def inbox_label_matrix
    builder = V2::Reports::InboxLabelMatrixBuilder.new(
      account: Current.account,
      params: inbox_label_matrix_params
    )
    render json: builder.build
  end

  def first_response_time_distribution
    builder = V2::Reports::FirstResponseTimeDistributionBuilder.new(
      account: Current.account,
      params: first_response_time_distribution_params
    )
    render json: builder.build
  end

  OUTGOING_MESSAGES_ALLOWED_GROUP_BY = %w[agent team inbox label].freeze

  def outgoing_messages_count
    return head :unprocessable_entity unless OUTGOING_MESSAGES_ALLOWED_GROUP_BY.include?(params[:group_by])

    builder = V2::Reports::OutgoingMessagesCountBuilder.new(Current.account, outgoing_messages_count_params)
    render json: builder.build
  end

  private

  def generate_xlsx(filename, headers, report_data, is_traffic: false)
    package = ::Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: 'Report') do |sheet|
      if is_traffic
        sheet.add_row [I18n.t('reports.conversation_traffic_csv.timezone'), @timezone]
      else
        sheet.add_row [I18n.t('reports.period', since: Date.strptime(params[:since], '%s'), until: Date.strptime(params[:until], '%s'))]
        sheet.add_row headers if headers.present?
      end
      
      report_data.each do |row|
        sheet.add_row row
      end
    end

    response.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.xlsx"
    render plain: package.to_stream.read
  end

  def check_authorization
    authorize :report, :view?
  end

  def common_params
    {
      type: params[:type].to_sym,
      id: params[:id],
      group_by: params[:group_by],
      business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
    }
  end

  def current_summary_params
    common_params.merge({
                          since: range[:current][:since],
                          until: range[:current][:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def previous_summary_params
    common_params.merge({
                          since: range[:previous][:since],
                          until: range[:previous][:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def report_params
    common_params.merge({
                          metric: params[:metric],
                          since: params[:since],
                          until: params[:until],
                          timezone_offset: params[:timezone_offset]
                        })
  end

  def conversation_params
    {
      type: params[:type].to_sym,
      user_id: params[:user_id],
      page: params[:page].presence || 1
    }
  end

  def range
    {
      current: {
        since: params[:since],
        until: params[:until]
      },
      previous: {
        since: (params[:since].to_i - (params[:until].to_i - params[:since].to_i)).to_s,
        until: params[:since]
      }
    }
  end

  def build_summary(method)
    builder = V2::Reports::Conversations::MetricBuilder
    current_summary = builder.new(Current.account, current_summary_params).send(method)
    previous_summary = builder.new(Current.account, previous_summary_params).send(method)
    current_summary.merge(previous: previous_summary)
  end

  def conversation_metrics
    V2::ReportBuilder.new(Current.account, conversation_params).conversation_metrics
  end

  def inbox_label_matrix_params
    {
      since: params[:since],
      until: params[:until],
      inbox_ids: params[:inbox_ids],
      label_ids: params[:label_ids]
    }
  end

  def first_response_time_distribution_params
    {
      since: params[:since],
      until: params[:until]
    }
  end

  def outgoing_messages_count_params
    {
      group_by: params[:group_by],
      since: params[:since],
      until: params[:until]
    }
  end
end
