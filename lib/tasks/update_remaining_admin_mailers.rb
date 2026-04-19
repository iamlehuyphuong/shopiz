require 'fileutils'

DIVIDER = "<hr style=\"border: 0; border-bottom: 1px solid #E2E8F0; margin: 24px 0;\" />"

update_map = {}

update_map['app/views/mailers/administrator_notifications/account_notification_mailer/contact_import_failed.liquid'] = <<~LIQUID
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Contact Import Failed</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    Your CSV contact import process has failed. Please verify the file format and required fields before trying again.
  </p>
  #{DIVIDER}
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Nhập Danh Bạ Thất Bại</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    Tiến trình nhập danh bạ từ tệp CSV của bạn đã bị lỗi. Vui lòng kiểm tra lại định dạng tệp và các thông tin bắt buộc trước khi thử lại.
  </p>
LIQUID

update_map['app/views/mailers/administrator_notifications/account_notification_mailer/contact_import_complete.liquid'] = <<~LIQUID
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Contact Import Completed</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
    Your internal contact import sequence has finished successfully.
  </p>
  <ul style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    <li>Succeeded: <strong>{{ meta['imported_contacts'] }}</strong> records</li>
    <li>Failed: <strong>{{ meta['failed_contacts'] }}</strong> records</li>
  </ul>
  #{DIVIDER}
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Nhập Danh Bạ Hoàn Tất</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
    Tiến trình nhập danh bạ nội bộ của bạn đã hoàn tất thành công.
  </p>
  <ul style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    <li>Thành công: <strong>{{ meta['imported_contacts'] }}</strong> bản ghi</li>
    <li>Lỗi: <strong>{{ meta['failed_contacts'] }}</strong> bản ghi</li>
  </ul>
LIQUID

update_map['app/views/mailers/administrator_notifications/account_notification_mailer/contact_export_complete.liquid'] = <<~LIQUID
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Contact Export Completed</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    Your customer contact export data is ready to download. The file link is valid for a short term.
  </p>
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
    <tr>
      <td align="left">
        <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Download File</a>
      </td>
    </tr>
  </table>
  #{DIVIDER}
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Xuất Danh Bạ Thành Công</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    Dữ liệu danh bạ khách hàng của bạn đã sẵn sàng để tải xuống. Tệp tải về sẽ có hiệu lực trong thời gian ngắn.
  </p>
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
    <tr>
      <td align="left">
        <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Tải Tệp Ngay</a>
      </td>
    </tr>
  </table>
LIQUID

update_map['app/views/mailers/administrator_notifications/account_notification_mailer/automation_rule_disabled.liquid'] = <<~LIQUID
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Automation Rule Disabled</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
    Please note, your automation rule <strong>{{ meta['rule_name'] }}</strong> was disabled by the system due to an invalid configuration.
  </p>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    This usually happens when you remove a "Custom Attribute" that is used in this rule. Please verify your settings to prevent further service interruptions.
  </p>
  #{DIVIDER}
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Quy Tắc Tự Động Hoá Bị Vô Hiệu</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
    Xin lưu ý, quy tắc tự động hóa <strong>{{ meta['rule_name'] }}</strong> đã tự động bị vô hiệu hệ thống do cấu hình không hợp lệ.
  </p>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    Lỗi này thường xảy ra khi bạn lỡ tay xóa một "Thuộc tính tùy chỉnh" (Custom Attribute) đang được sử dụng trong quy tắc này. Vui lòng kiểm tra lại thiết lập để phòng tránh gián đoạn dịch vụ.
  </p>
LIQUID

update_map['app/views/mailers/administrator_notifications/account_notification_mailer/account_deletion_for_inactivity.liquid'] = <<~LIQUID
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Account Deletion Notice</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
    Your Shopiz account workspace (<strong>{{ meta['account_name'] }}</strong>) has been inactive for a long time. 
    To optimize space, this account will be PERMANENTLY DELETED on <strong>{{ meta['deletion_date'] }}</strong>.
  </p>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    If you wish to retain it, simply log in before the deadline and select cancel deletion:
  </p>
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
    <tr>
      <td align="left">
        <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Log In Now</a>
      </td>
    </tr>
  </table>
  #{DIVIDER}
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Cảnh Báo Xóa Tài Khoản</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
    Tài khoản Shopiz của bạn (<strong>{{ meta['account_name'] }}</strong>) đã không hoạt động trong một thời gian dài. 
    Để tối ưu hóa không gian cho các doanh nghiệp đang hoạt động, tài khoản này sẽ tự động bị XOÁ VĨNH VIỄN vào ngày <strong>{{ meta['deletion_date'] }}</strong>.
  </p>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    Nếu bạn muốn giữ lại tài khoản, đơn giản chỉ cần đăng nhập lại trước thời hạn trên và nhấn vào nút huỷ yêu cầu xoá:
  </p>
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
    <tr>
      <td align="left">
        <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Đăng Nhập Ngay</a>
      </td>
    </tr>
  </table>
LIQUID

update_map['app/views/mailers/administrator_notifications/account_notification_mailer/account_deletion_user_initiated.liquid'] = <<~LIQUID
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Workspace Deletion Request</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
    An administrator has requested the deletion of Workspace <strong>{{ meta['account_name'] }}</strong> from the Shopiz system. This process fully completes on <strong>{{ meta['deletion_date'] }}</strong>.
  </p>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    Note that while the workspace hasn't been removed, you can access the system settings to cancel this execution at any time:
  </p>
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
    <tr>
      <td align="left">
        <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Cancel Deletion</a>
      </td>
    </tr>
  </table>
  #{DIVIDER}
  <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Yêu Cầu Xóa Workspace</h2>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
    Một Quản trị viên (Admin) vừa gửi yêu cầu xoá Workspace <strong>{{ meta['account_name'] }}</strong> khỏi hệ thống Shopiz. Tiến trình này sẽ được thực thi hoàn tất vào ngày <strong>{{ meta['deletion_date'] }}</strong>.
  </p>
  <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
    Xin lưu ý, trong lúc Workspace chưa bị xoá hoãn toàn, bạn có quyền can thiệp vào cài đặt hệ thống và chủ động Huỷ lệnh xử lý bất cứ lúc nào qua đường dẫn bên dưới:
  </p>
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
    <tr>
      <td align="left">
        <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Huỷ Lệnh Xoá</a>
      </td>
    </tr>
  </table>
LIQUID


update_map.each do |file_path, content|
  File.write(file_path, content)
  puts "✅ Updated \#{file_path}"
end
