class DailySummaryMailer < ApplicationMailer
  def report_email
    @inbox_daily_summary = params[:inbox_daily_summary]
    @content = params[:content]
    @account = params[:account]
    
    users = User.where(id: @inbox_daily_summary.user_ids)
    emails = users.pluck(:email)
    
    return if emails.empty?
    
    inboxes = Inbox.where(id: @inbox_daily_summary.inbox_ids)
    inbox_names = inboxes.limit(2).pluck(:name).join(', ')
    inbox_names += " " + I18n.t('daily_summary_mailer.report_email.and_more', count: inboxes.count - 2) if inboxes.count > 2
    
    @inbox_names = inbox_names
    mail(to: emails, subject: I18n.t('daily_summary_mailer.report_email.subject', inbox_names: inbox_names))
  end
end
