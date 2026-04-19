require 'fileutils'

DIVIDER = "<hr style=\"border: 0; border-bottom: 1px solid #E2E8F0; margin: 24px 0;\" />"

def find_files(pattern)
  Dir.glob(pattern)
end

update_map = {}

# Disconnect
find_files("app/views/mailers/administrator_notifications/**/*_disconnect.liquid").each do |file|
  channel_name = file.split('/').last.gsub('_disconnect.liquid', '').capitalize
  update_map[file] = <<~LIQUID
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Channel Disconnected</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Your connection to the <strong>#{channel_name}</strong> platform has been disconnected. You won't be able to receive or send messages from this channel until it is reconnected.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Please go to your channel settings to re-authenticate as soon as possible.
    </p>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Kênh Mất Kết Nối</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Kết nối với nền tảng <strong>#{channel_name}</strong> của bạn đã bị ngắt. Bạn sẽ không thể tiếp tục nhận tin nhắn từ kênh này cho đến khi kết nối được khôi phục.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Vui lòng truy cập trang quản lý các kênh kết nối để xác thực lại sớm nhất có thể.
    </p>
  LIQUID
end

# Contact Import (Channel Mailers, if any)
find_files("app/views/mailers/**/*_notifications_mailer/contact_import_*.liquid").each do |file|
  status_vi = file.include?('failed') ? "Thất bại" : "Hoàn tất"
  status_en = file.include?('failed') ? "Failed" : "Completed"
  update_map[file] = <<~LIQUID
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Contact Import #{status_en}</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      The system has finished processing your recent contact import batch.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Status: <strong>#{status_en}</strong>.
    </p>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Nhập Danh Bạ #{status_vi}</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Hệ thống vừa hoàn tất tiến trình xử lý hàng loạt tệp danh bạ khách hàng bạn tải lên gần đây.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Trạng thái: <strong>#{status_vi}</strong>.
    </p>
  LIQUID
end

# Contact Export (Channel Mailers, if any)
find_files("app/views/mailers/**/*_notifications_mailer/contact_export_complete.liquid").each do |file|
  update_map[file] = <<~LIQUID
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Contact Export Completed</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Your contact export data file is ready to download.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Download Now</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Xuất Danh Bạ Thành Công</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Tệp dữ liệu xuất danh bạ của bạn đã sẵn sàng để tải xuống.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Tải Xuống Ngay</a>
        </td>
      </tr>
    </table>
  LIQUID
end

# Automation Rule
find_files("app/views/mailers/**/*_notifications_mailer/automation_rule_disabled.liquid").each do |file|
  update_map[file] = <<~LIQUID
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Automation Rule Disabled</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      One of your Automation Rules was automatically disabled due to invalid configurations, bad parameters, or system limits.
    </p>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Bộ Quy Tắc Đã Bị Vô Hiệu</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Một trong số các bộ quy tắc tự động hóa Automation Rule của bạn vừa bị vô hiệu hoá do lỗi cấu hình, chứa tham số không hợp lệ hoặc bị giới hạn bởi hệ thống.
    </p>
  LIQUID
end

# Account Deletion warning
find_files("app/views/mailers/**/*_notifications_mailer/account_deletion_*.liquid").each do |file|
  update_map[file] = <<~LIQUID
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Account Deletion Warning</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Our systems show that your Shopiz workspace is scheduled for permanent deletion (either user-initiated or due to prolonged inactivity).
    </p>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Cảnh Báo Xóa Tài Khoản</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Hệ thống ghi nhận tài khoản Shopiz của bạn đang trong lộ trình xoá vĩnh viễn (do bạn chủ động yêu cầu hoặc do tài khoản ngưng hoạt động kéo dài).
    </p>
  LIQUID
end

# Account Deleted compliance
find_files("app/views/mailers/**/*_compliance_mailer/account_deleted.liquid").each do |file|
  update_map[file] = <<~LIQUID
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Account Deleted</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      We regret to inform you that your company's account on Shopiz has been successfully deleted according to data compliance laws. All contact data and conversations belonging to this workspace have been purged.
    </p>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Tài Khoản Đã Bị Xoá</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Rất tiếc phải thông báo rằng tài khoản công ty của bạn trên hệ thống Shopiz đã được xoá thành công theo luật tuân thủ dữ liệu. Tất cả dữ liệu danh bạ và các hộp thoại thuộc về không gian hoạt động này đã được làm sạch.
    </p>
  LIQUID
end


puts "Updating \#{update_map.size} Admin Notification templates..."
update_map.each do |file_path, content|
  File.write(file_path, content)
  puts "✅ Updated \#{file_path}"
end
