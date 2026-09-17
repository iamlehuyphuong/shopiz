class Account::ContactsExportJob < ApplicationJob
  queue_as :low

  def perform(account_id, user_id, column_names, params)
    @account = Account.find(account_id)
    @params = params
    @account_user = @account.users.find(user_id)

    headers = valid_headers(column_names)
    generate_xlsx(headers)
    send_mail
  end

  private

  def generate_xlsx(headers)
    package = ::Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: 'Contacts') do |sheet|
      sheet.add_row headers
      contacts.each do |contact|
        sheet.add_row headers.map { |header| contact.send(header) }
      end
    end

    attach_export_file(package.to_stream.read)
  end

  def contacts
    scope = if @params.present? && @params[:payload].present? && @params[:payload].any?
      result = ::Contacts::FilterService.new(@account, @account_user, @params).perform
      result[:contacts]
    elsif @params[:label].present?
      @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2')).tagged_with(@params[:label], any: true)
    else
      @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2'))
    end
    scope.includes(:inboxes)
  end

  def valid_headers(column_names)
    allowed_columns = Contact.column_names + ['inbox_names']
    (column_names.presence || default_columns) & allowed_columns
  end

  def attach_export_file(xlsx_data)
    return if xlsx_data.blank?

    @account.contacts_export.attach(
      io: StringIO.new(xlsx_data),
      filename: "#{@account.name}_#{@account.id}_contacts.xlsx",
      content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  def send_mail
    file_url = account_contact_export_url
    mailer = AdministratorNotifications::AccountNotificationMailer.with(account: @account)
    mailer.contact_export_complete(file_url, @account_user.email)&.deliver_later
  end

  def account_contact_export_url
    Rails.application.routes.url_helpers.rails_blob_url(@account.contacts_export)
  end

  def default_columns
    %w[id name email phone_number created_at inbox_names]
  end
end
