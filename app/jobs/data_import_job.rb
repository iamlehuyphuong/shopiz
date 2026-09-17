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
    rescue StandardError => e
      handle_import_error(e)
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
        xlsx_rows(file).each { |row| rows << row.to_h.with_indifferent_access }
      end
      records, rejected_records = @manager.process_rows(rows)
    else
      # Old way: process line by line (contacts)
      with_import_file do |file|
        xlsx_rows(file).each do |row|
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
    save_failed_records_xlsx(rejected_records)
  end

  def append_rejected_record(row, record, rejected_records)
    row['errors'] = record.errors.full_messages.join(', ')
    rejected_records << row
  end

  def update_data_import_status(processed_records, rejected_records)
    @data_import.update!(status: :completed, processed_records: processed_records, total_records: processed_records + rejected_records)
  end

  def save_failed_records_xlsx(rejected_records)
    xlsx_data = generate_xlsx_data(rejected_records)
    return if xlsx_data.blank?

    @data_import.failed_records.attach(
      io: StringIO.new(xlsx_data), 
      filename: "#{Time.zone.today.strftime('%Y%m%d')}_#{@data_import.data_type}.xlsx",
      content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  def generate_xlsx_data(rejected_records)
    headers = xlsx_headers
    headers << 'errors'
    return if rejected_records.blank?

    package = ::Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: 'Errors') do |sheet|
      sheet.add_row headers
      rejected_records.each do |record|
        sheet.add_row headers.map { |h| record[h] }
      end
    end
    
    package.to_stream.read
  end

  def handle_import_error(error) # rubocop:disable Lint/UnusedMethodArgument
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

  def xlsx_headers
    headers = []
    with_import_file do |file|
      xlsx = Roo::Excelx.new(file.path)
      headers = xlsx.row(1).map { |h| h.to_s.strip }
    end
    headers
  end

  def xlsx_rows(file)
    xlsx = Roo::Excelx.new(file.path)
    headers = xlsx.row(1).map { |h| h.to_s.strip }
    rows = []
    return rows if xlsx.last_row.nil? || xlsx.last_row < 2

    (2..xlsx.last_row).each do |i|
      row = Hash[[headers, xlsx.row(i)].transpose]
      rows << row
    end
    rows
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
