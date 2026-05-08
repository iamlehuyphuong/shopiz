class Api::V1::Widget::DirectUploadsController < ActiveStorage::DirectUploadsController
  include WebsiteTokenHelper
  before_action :set_web_widget
  before_action :set_contact

  def create
    return if @contact.nil? || @current_account.nil?

    blob_args = params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, metadata: {}).to_h.symbolize_keys
    existing_blob = ActiveStorage::Blob.find_by(checksum: blob_args[:checksum], byte_size: blob_args[:byte_size])

    if existing_blob
      render json: direct_upload_json(existing_blob)
    else
      super
    end
  end
end
