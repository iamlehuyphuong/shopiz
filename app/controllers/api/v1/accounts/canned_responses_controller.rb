class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    render json: canned_responses.map { |cr| serialize_canned_response(cr) }
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params)
    @canned_response.save!
    render json: serialize_canned_response(@canned_response)
  end

  def update
    @canned_response.update!(canned_response_params)
    purge_removed_files
    render json: serialize_canned_response(@canned_response)
  end

  def destroy
    @canned_response.destroy!
    head :ok
  end

  def export
    canned_responses_list = Current.account.canned_responses.order(:id)
    package = Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: 'Canned Responses') do |sheet|
      sheet.add_row ['ID', 'Short Code', 'Content', 'Account ID', 'Created At', 'Updated At']
      canned_responses_list.each do |cr|
        sheet.add_row [cr.id, cr.short_code, cr.content, cr.account_id, cr.created_at, cr.updated_at]
      end
    end
    send_data package.to_stream.read, filename: "canned_responses_#{Time.now.to_i}.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def import
    render json: { error: 'No file provided' }, status: :unprocessable_entity and return if params[:import_file].blank?

    result = CannedResponses::ImportService.new(Current.account, params[:import_file]).perform
    render json: result, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def canned_response_params
    params.require(:canned_response).permit(:short_code, :content, files: [])
  end

  def purge_removed_files
    return if params[:canned_response][:removed_file_ids].blank?

    params[:canned_response][:removed_file_ids].each do |file_id|
      attachment = @canned_response.files.find { |f| f.id == file_id.to_i }
      attachment&.purge_later
    end
  end

  def canned_responses
    scope = Current.account.canned_responses.with_attached_files
    if params[:search]
      scope.where('short_code ILIKE :search OR content ILIKE :search', search: "%#{params[:search]}%")
           .order_by_search(params[:search])
    else
      scope
    end
  end

  def serialize_canned_response(canned_response)
    {
      id: canned_response.id,
      account_id: canned_response.account_id,
      short_code: canned_response.short_code,
      content: canned_response.content,
      created_at: canned_response.created_at,
      updated_at: canned_response.updated_at,
      files: serialize_files(canned_response)
    }
  end

  def serialize_files(canned_response)
    return [] unless canned_response.files.attached?

    canned_response.files.map do |file|
      {
        id: file.id,
        filename: file.filename.to_s,
        content_type: file.content_type,
        byte_size: file.byte_size,
        url: url_for(file),
        blob_signed_id: file.signed_id
      }
    end
  end
end
