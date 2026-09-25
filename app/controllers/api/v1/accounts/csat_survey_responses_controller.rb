class Api::V1::Accounts::CsatSurveyResponsesController < Api::V1::Accounts::BaseController
  include Sift
  include DateRangeHelper

  RESULTS_PER_PAGE = 25

  before_action :check_authorization
  before_action :set_csat_survey_responses, only: [:index, :metrics, :download]
  before_action :set_current_page, only: [:index]
  before_action :set_current_page_surveys, only: [:index]
  before_action :set_total_sent_messages_count, only: [:metrics]

  sort_on :created_at, type: :datetime

  def index; end

  def metrics
    @total_count = @csat_survey_responses.count
    @ratings_count = @csat_survey_responses.group(:rating).count
  end

  def download
    package = ::Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: 'CSAT Report') do |sheet|
      headers = [
        I18n.t('reports.csat.headers.agent_name'),
        I18n.t('reports.csat.headers.rating'),
        I18n.t('reports.csat.headers.feedback'),
        I18n.t('reports.csat.headers.contact_name'),
        I18n.t('reports.csat.headers.contact_email_address'),
        I18n.t('reports.csat.headers.contact_phone_number'),
        I18n.t('reports.csat.headers.link_to_the_conversation'),
        I18n.t('reports.csat.headers.recorded_at')
      ]
      headers << I18n.t('reports.csat.headers.review_notes') if ChatwootApp.enterprise?
      sheet.add_row headers

      @csat_survey_responses.each do |csat_response|
        assigned_agent = csat_response.assigned_agent
        contact = csat_response.contact
        conversation = csat_response.conversation
        row = [
          assigned_agent ? "#{assigned_agent.name} (#{assigned_agent.email})" : nil,
          csat_response.rating,
          csat_response.feedback_message.presence,
          contact&.name.presence,
          contact&.email.presence,
          contact&.phone_number.presence,
          conversation ? app_account_conversation_url(account_id: Current.account.id, id: conversation.display_id) : nil,
          csat_response.created_at
        ]
        row << csat_response.csat_review_notes if ChatwootApp.enterprise?
        sheet.add_row row
      end

      sheet.add_row []
      sheet.add_row [I18n.t('reports.period', since: Date.strptime(params[:since], '%s'), until: Date.strptime(params[:until], '%s'))]
    end

    response.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    response.headers['Content-Disposition'] = 'attachment; filename=csat_report.xlsx'
    render plain: package.to_stream.read
  end

  private

  def set_total_sent_messages_count
    @csat_messages = Current.account.messages.input_csat
    @csat_messages = @csat_messages.where(created_at: range) if range.present?
    @total_sent_messages_count = @csat_messages.count
  end

  def set_csat_survey_responses
    base_query = Current.account.csat_survey_responses.includes([:conversation, :assigned_agent, :contact])
    @csat_survey_responses = filtrate(base_query).filter_by_created_at(range)
                                                 .filter_by_assigned_agent_id(params[:user_ids])
                                                 .filter_by_inbox_id(params[:inbox_id])
                                                 .filter_by_team_id(params[:team_id])
                                                 .filter_by_rating(params[:rating])
  end

  def set_current_page_surveys
    @csat_survey_responses = @csat_survey_responses.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end

Api::V1::Accounts::CsatSurveyResponsesController.prepend_mod_with('Api::V1::Accounts::CsatSurveyResponsesController')
