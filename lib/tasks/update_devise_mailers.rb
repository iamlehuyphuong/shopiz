require 'fileutils'

DIVIDER = "<hr style=\"border: 0; border-bottom: 1px solid #E2E8F0; margin: 24px 0;\" />"

TEMPLATE_MAPPINGS = {
  "app/views/devise/mailer/confirmation_instructions.html.erb" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Welcome to Shopiz!</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{% if user.name %}{{ user.name }}{% else %}{{ user.available_name }}{% endif %}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Thank you for joining us. You now have access to a powerful customer engagement toolkit. To get started, please verify your email address to secure your account.
    </p>

    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #F97316; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">
            Verify Email
          </a>
        </td>
      </tr>
    </table>

    <p style="color: #475569; font-size: 15px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      If the button above does not work, you can securely copy and paste the link below into your web browser:
    </p>

    <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 8px; padding: 16px; word-break: break-all;">
      <a href="{{ action_url }}" style="color: #3B82F6; font-size: 13px; text-decoration: none;">{{ action_url }}</a>
    </div>

    <p style="color: #64748B; font-size: 13px; line-height: 1.6; margin-top: 24px; margin-bottom: 0;">
      If you did not create an account with Shopiz, please safely ignore this email.
    </p>

    #{DIVIDER}

    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Chào mừng đến với Shopiz!</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{% if user.name %}{{ user.name }}{% else %}{{ user.available_name }}{% endif %}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Cảm ơn bạn đã tham gia cùng chúng tôi. Bạn đã có quyền truy cập vào bộ công cụ tương tác khách hàng thông minh. Để bắt đầu, vui lòng xác thực địa chỉ email để bảo mật thông tin tài khoản của bạn.
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
      Nếu bạn không tạo tài khoản với Shopiz, xin vui lòng bỏ qua email này một cách an toàn. Đừng lo, dữ liệu của bạn không bị làm sao cả.
    </p>
  LIQUID

  "app/views/devise/mailer/reset_password_instructions.html.erb" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Password Reset Request</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{% if user.name %}{{ user.name }}{% else %}{{ user.available_name }}{% endif %}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      We received a request to reset your password. Do not worry, just click the button below to set a new password:
    </p>

    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">
            Change Password
          </a>
        </td>
      </tr>
    </table>

    <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 8px; padding: 16px; margin-bottom: 24px; word-break: break-all;">
      <a href="{{ action_url }}" style="color: #3B82F6; font-size: 13px; text-decoration: none;">{{ action_url }}</a>
    </div>

    <p style="color: #64748B; font-size: 13px; line-height: 1.6; margin-top: 24px; margin-bottom: 0;">
      Note: Your password won't change until you access the link above and create a new one. If you didn't request a password reset, please ignore this email.
    </p>

    #{DIVIDER}

    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Yêu Cầu Đặt Lại Mật Khẩu</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{% if user.name %}{{ user.name }}{% else %}{{ user.available_name }}{% endif %}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Đừng lo lắng, hãy nhấn vào nút dưới đây để thiết lập mật khẩu mới ngay:
    </p>

    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">
            Đổi Mật Khẩu Mới
          </a>
        </td>
      </tr>
    </table>

    <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 8px; padding: 16px; margin-bottom: 24px; word-break: break-all;">
      <a href="{{ action_url }}" style="color: #3B82F6; font-size: 13px; text-decoration: none;">{{ action_url }}</a>
    </div>

    <p style="color: #64748B; font-size: 13px; line-height: 1.6; margin-top: 24px; margin-bottom: 0;">
      Lưu ý: Mật khẩu sẽ không bị thay đổi trừ khi bạn truy cập vào link trên và tạo mật khẩu mới. Nếu bạn không yêu cầu thay đổi mật khẩu, vui lòng bỏ qua email này.
    </p>
  LIQUID

  "app/views/devise/mailer/password_change.html.erb" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Password Successfully Changed</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{% if user.name %}{{ user.name }}{% else %}{{ user.available_name }}{% endif %}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      We're contacting you to let you know that your password for Shopiz has been successfully changed.
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      If you made this change, no further action is required.
    </p>

    <div style="background-color: #FEF2F2; border: 1px solid #FECACA; border-radius: 8px; padding: 16px; margin-top: 24px;">
      <p style="color: #991B1B; font-size: 14px; margin: 0;">
        <strong>SECURITY NOTIFICATION:</strong> If you did not change your password, your account might be compromised. Please contact our support team immediately.
      </p>
    </div>

    #{DIVIDER}

    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Mật Khẩu Đã Thay Đổi Thành Công</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{% if user.name %}{{ user.name }}{% else %}{{ user.available_name }}{% endif %}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Chúng tôi xin thông báo rằng mật khẩu tài khoản Shopiz của bạn đã được thay đổi thành công.
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Nếu bạn là người thực hiện hành động này, bạn không cần phải làm gì thêm nữa.
    </p>

    <div style="background-color: #FEF2F2; border: 1px solid #FECACA; border-radius: 8px; padding: 16px; margin-top: 24px;">
      <p style="color: #991B1B; font-size: 14px; margin: 0;">
        <strong>CẢNH BÁO BẢO MẬT:</strong> Nếu bạn không hề thay đổi mật khẩu, rất có thể tài khoản của bạn đã bị xâm nhập. Vui lòng liên hệ với bộ phận hỗ trợ của chúng tôi ngay lập tức.
      </p>
    </div>
  LIQUID

  "app/views/devise/mailer/unlock_instructions.html.erb" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Account Temporarily Locked</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{% if user.name %}{{ user.name }}{% else %}{{ user.available_name }}{% endif %}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Your account has been locked due to an excessive number of unsuccessful sign-in attempts.
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Click the link below to unlock your account and regain access:
    </p>

    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">
            Unlock My Account
          </a>
        </td>
      </tr>
    </table>

    <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 8px; padding: 16px; margin-bottom: 24px; word-break: break-all;">
      <a href="{{ action_url }}" style="color: #3B82F6; font-size: 13px; text-decoration: none;">{{ action_url }}</a>
    </div>

    #{DIVIDER}

    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Tài Khoản Tạm Thời Bị Khoá</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{% if user.name %}{{ user.name }}{% else %}{{ user.available_name }}{% endif %}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Tài khoản của bạn đã bị khoá tạm thời do hệ thống ghi nhận có quá nhiều lượt đăng nhập sai mật khẩu.
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Vui lòng nhấp vào nút dưới đây để mở khoá tài khoản và tiếp tục truy cập an toàn:
    </p>

    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">
            Mở Khoá Tài Khoản
          </a>
        </td>
      </tr>
    </table>

    <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 8px; padding: 16px; margin-bottom: 24px; word-break: break-all;">
      <a href="{{ action_url }}" style="color: #3B82F6; font-size: 13px; text-decoration: none;">{{ action_url }}</a>
    </div>
  LIQUID
}

puts "Updating #{TEMPLATE_MAPPINGS.size} Bilingual Devise templates..."
TEMPLATE_MAPPINGS.each do |file_path, content|
  File.write(file_path, content)
  puts "✅ Updated #{file_path}"
end
