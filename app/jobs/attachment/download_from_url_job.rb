class Attachment::DownloadFromUrlJob < ApplicationJob
  queue_as :low

  MAX_DOWNLOAD_SIZE = 100 * 1024 * 1024

  def perform(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return unless attachment
    return if attachment.file.attached?
    return if attachment.external_url.blank?

    attachment_file = Down.download(attachment.external_url, max_size: MAX_DOWNLOAD_SIZE)
    raise Down::Error, 'Invalid file' if attachment_file.original_filename.blank?

    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )

    # Trigger message broadcast so the frontend gets the updated active storage URL
    if attachment.message
      attachment.message.reload
      attachment.message.send_update_event
    end
  rescue Down::NotFound
    Rails.logger.info "Attachment::DownloadFromUrlJob: file not found at #{attachment.external_url}"
  rescue Down::Error => e
    Rails.logger.error "Attachment::DownloadFromUrlJob error for #{attachment.external_url}: #{e.class} - #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Attachment::DownloadFromUrlJob Failed for ID: #{attachment_id} - Error: #{e.message}"
  end
end
