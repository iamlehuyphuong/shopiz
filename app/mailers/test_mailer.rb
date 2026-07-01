class TestMailer < ApplicationMailer
  def test_email(email)
    mail(to: email, subject: 'Shopiz - Test Email Configuration') do |format|
      format.html { render plain: 'Your SMTP settings are configured correctly on Shopiz!' }
    end
  end
end
