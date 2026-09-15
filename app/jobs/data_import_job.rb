# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low
  retry_on ActiveStorage::FileNotFoundError, wait: 1.minute, attempts: 3

  def perform(data_import)
    @data_import = data_import
    @manager = "DataImport::#{@data_import.data_type.singularize.camelize}Manager".constantize.new(@data_import.account)
    
    begin
      process_import_file
      send_import_notification_to_admin
    rescue CSV::MalformedCSVError => e
      handle_csv_error(e)
    end
  end

  private

  def process_import_file
    @data_import.update!(status: :processing)
    
    records = []
    rejected_records = []

    if @manager.respond_to?(:process_rows)
      # New way: manager handles all rows together (good for products with variants)
      rows = []
      with_import_file do |file|
        csv_reader(file).each { |row| rows << row.to_h.with_indifferent_access }
      end
      records, rejected_records = @manager.process_rows(rows)
    else
      # Old way: process line by line (contacts)
      with_import_file do |file|
        csv_reader(file).each do |row|
          current_record = @manager.build_contact(row.to_h.with_indifferent_access)
          if current_record.valid?
            records << current_record
          else
            append_rejected_record(row, current_record, rejected_records)
          end
        end
      end
      
      # For contacts, we bulk import them here
      # <struct ActiveRecord::Import::Result failed_instances=[], num_inserts=1, ids=[444, 445], results=[]>
      Contact.import(records, synchronize: records, on_duplicate_key_ignore: true, track_validation_failures: true, validate: true, batch_size: 1000)
    end

    update_data_import_status(records.length, rejected_records.length)
    save_failed_records_csv(rejected_records)
  end

  def append_rejected_record(row, record, rejected_records)
    row['errors'] = record.errors.full_messages.join(', ')
    rejected_records << row
  end

  def update_data_import_status(processed_records, rejected_records)
    @data_import.update!(status: :completed, processed_records: processed_records, total_records: processed_records + rejected_records)
  end

  def save_failed_records_csv(rejected_records)
    csv_data = generate_csv_data(rejected_records)
    return if csv_data.blank?

    @data_import.failed_records.attach(
      io: StringIO.new(csv_data), 
      filename: "#{Time.zone.today.strftime('%Y%m%d')}_#{@data_import.data_type}.csv",
      content_type: 'text/csv'
    )
  end

  def generate_csv_data(rejected_records)
    headers = csv_headers
    headers << 'errors'
    return if rejected_records.blank?

    CSV.generate do |csv|
      csv << headers
      rejected_records.each do |record|
        csv << record
      end
    end
  end

  def handle_csv_error(error) # rubocop:disable Lint/UnusedMethodArgument
    @data_import.update!(status: :failed)
    send_import_failed_notification_to_admin
  end

  def send_import_notification_to_admin
    if @data_import.data_type == 'products'
      AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).product_import_complete(@data_import).deliver_later
    else
      AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_complete(@data_import).deliver_later
    end
  end

  def send_import_failed_notification_to_admin
    if @data_import.data_type == 'products'
      AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).product_import_failed.deliver_later
    else
      AdministratorNotifications::AccountNotificationMailer.with(account: @data_import.account).contact_import_failed.deliver_later
    end
  end

  def csv_headers
    header_row = nil
    with_import_file do |file|
      header_row = csv_reader(file).first
    end
    header_row&.headers || []
  end

  def csv_reader(file)
    file.rewind
    raw_data = file.read
    utf8_data = raw_data.force_encoding('UTF-8')
    clean_data = utf8_data.valid_encoding? ? utf8_data : utf8_data.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8')

    CSV.new(StringIO.new(clean_data), headers: true)
  end

  def with_import_file
    temp_dir = Rails.root.join('tmp/imports')
    FileUtils.mkdir_p(temp_dir)

    @data_import.import_file.open(tmpdir: temp_dir) do |file|
      file.binmode
      yield file
    end
  end
end
