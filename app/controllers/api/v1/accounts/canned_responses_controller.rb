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
