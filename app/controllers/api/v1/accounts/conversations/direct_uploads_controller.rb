class Api::V1::Accounts::Conversations::DirectUploadsController < ActiveStorage::DirectUploadsController
  include EnsureCurrentAccountHelper
  before_action :current_account
  before_action :conversation

  def create
    return if @conversation.nil? || @current_account.nil?

    blob_args = params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, metadata: {}).to_h.symbolize_keys
    existing_blob = ActiveStorage::Blob.find_by(checksum: blob_args[:checksum], byte_size: blob_args[:byte_size])

    if existing_blob
      render json: direct_upload_json(existing_blob)
    else
      super
    end
  end

  private

  def conversation
    @conversation ||= Current.account.conversations.find_by(display_id: params[:conversation_id])
  end
end
