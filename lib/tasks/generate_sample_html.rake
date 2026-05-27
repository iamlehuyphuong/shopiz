namespace :email_templates do
  task generate_sample: :environment do
    layout = EmailTemplate.find_by(name: 'layouts/mailer/base')

    liquid_content = <<~LIQUID
      <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Welcome to {% if global_config['BRAND_NAME'] %}{{ global_config['BRAND_NAME'] }}{% else %}Flowify{% endif %}! 👋</h2>
      
      <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
        Hi <strong>{% if user.name %}{{ user.name }}{% else %}there{% endif %}</strong>,
      </p>
      
      <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
        Cảm ơn bạn đã tham gia cùng chúng tôi. Bạn đã có quyền truy cập vào bộ công cụ tương tác khách hàng mạnh mẽ. Để bắt đầu, vui lòng xác thực địa chỉ email để bảo mật tài khoản Của bạn.
      </p>
      
      <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
        <tr>
          <td align="left">
            <a href="{{ action_url }}" style="display: inline-block; background-color: #F97316; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(249, 115, 22, 0.4);">
              Xác thực Email
            </a>
          </td>
        </tr>
      </table>
      
      <p style="color: #475569; font-size: 15px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
        Nếu nút bấm phía trên không hoạt động, bạn có thể copy và dán đường link an toàn dưới đây vào trình duyệt web:
      </p>
      
      <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 8px; padding: 16px; word-break: break-all;">
        <a href="{{ action_url }}" style="color: #3B82F6; font-size: 13px; text-decoration: none;">{{ action_url }}</a>
      </div>
      
      <p style="color: #64748B; font-size: 13px; line-height: 1.6; margin-top: 24px; margin-bottom: 0;">
        Nếu bạn không tạo tài khoản với Flowify, bạn có thể bỏ qua email này một cách an toàn.
      </p>
    LIQUID

    mock_data = {
      'user' => { 'name' => 'Nguyễn Văn A', 'email' => 'alice@example.com' },
      'action_url' => 'https://app.flowify.vn/auth/confirmation?confirmation_token=abcdef123456',
      'global_config' => { 'BRAND_NAME' => 'Flowify Enterprise' }
    }

    content_parsed = Liquid::Template.parse(liquid_content).render(mock_data, strict_variables: false)
    final_html = Liquid::Template.parse(layout.body).render('content_for_layout' => content_parsed, 'mailer_action' => 'unlock_instructions', 'global_config' => mock_data['global_config'], strict_variables: false)

    File.write('sample_email_output.html', final_html)
    puts "Done"
  end
end
