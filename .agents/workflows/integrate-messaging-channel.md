---
description: Hướng dẫn chi tiết quy trình tích hợp một kênh nhắn tin mới (Messaging Channel) vào hệ thống Flowify, dựa trên thực tế triển khai TikTok và Zalo.
---

# Quy trình Tích hợp Kênh Nhắn tin Mới

Tài liệu này hướng dẫn các bước kỹ thuật để tích hợp một kênh nhắn tin (như TikTok Messenger, Zalo, WhatsApp, v.v.) vào Flowify. Quy trình này đảm bảo tính nhất quán về kiến trúc và độ tin cậy của dữ liệu.

## 1. Nghiên cứu & Chuẩn bị
Trước khi viết mã, hãy thực hiện các bước sau:
- **Tài liệu API**: Đọc kỹ tài liệu Webhook và Messaging API của nhà cung cấp.
- **Xác thực**: Xác định cơ chế Auth (OAuth2, App Secret, hay Long-lived Token).
- **Media**: Kiểm tra cách tải ảnh/video (Link trực tiếp hay cần API Download) và cách upload media.
- **Webhook**: Tìm hiểu cấu trúc payload và cơ chế verify signature.

## 2. Khởi tạo Cơ sở dữ liệu
Tạo Migration cho bảng lưu trữ thông tin kênh:
```bash
# Ví dụ cho kênh mang tên 'provider'
bundle exec rails generate migration CreateChannelProvider
```
Các trường bắt buộc trong migration:
- `access_token:string` (Encrypted)
- `refresh_token:string` (Encrypted)
- `expires_at:datetime`
- `account_id:integer` (Index)
- `provider_id:string` (ID của tài khoản bên phía nhà cung cấp, ví dụ: business_id, oa_id)

## 3. Xây dựng Model
Tạo tệp tại `app/models/channel/<provider>.rb`.
```ruby
class Channel::Provider < ApplicationRecord
  include Channelable
  include Reauthorizable
  self.table_name = 'channel_provider'

  # Mã hóa credentials
  if Chatwoot.encryption_configured?
    encrypts :access_token
    encrypts :refresh_token
  end

  validates :provider_id, uniqueness: true, presence: true
end
```

## 4. Kiến trúc Services (Modular Architecture)
Tổ chức code trong thư mục `app/services/<provider>/` để dễ bảo trì:

1.  **`auth_client.rb`**: Xử lý logic OAuth, lấy và làm mới Access Token.
2.  **`client.rb`**: Wrapper cho các HTTP request (GET profile, POST message, POST upload media).
3.  **`token_service.rb`**: Quản lý lifecycle của token. Sử dụng `Redis::LockManager` để tránh race condition khi nhiều process cùng refresh token.
4.  **`message_service.rb`**: Logic core để biến payload webhook thành bản ghi `Message` trong Flowify.
    - Xử lý tạo/tìm `Contact`.
    - Xử lý tạo/tìm `Conversation`.
    - Xử lý `attachments` (Download media từ provider -> Upload lên ActiveStorage).
    - Hỗ trợ `outgoing_echo` (đồng bộ tin nhắn nhân viên nhắn từ app ngoài).
5.  **`messaging_helpers.rb`**: Các method phụ trợ cho việc tìm kiếm hội thoại, xử lý attributes.
6.  **`send_on_<provider>_service.rb`**: Gọi bởi `Message#send_to_external_channel` khi nhân viên nhắn tin từ dashboard Flowify.

## 5. Xử lý Inbound (Webhooks)
- **Controller**: `app/controllers/webhooks/<provider>_controller.rb`.
  - **Bắt buộc**: Phải verify signature của request trước khi xử lý.
  - Sau khi verify, đẩy payload vào Job để xử lý async.
- **Job**: `app/jobs/webhooks/<provider>_events_job.rb`.
  - Kế thừa từ `MutexApplicationJob`.
  - Sử dụng khóa `conversation_id` để tin nhắn của cùng một hội thoại được xử lý tuần tự, tránh lỗi race condition.

## 6. Đồng bộ Lịch sử (Backfill)
- Xây dựng `HistorySyncService` để lấy danh sách hội thoại và tin nhắn cũ ngay sau khi người dùng kết nối kênh.
- Sử dụng `Recursive Job` (Job tự gọi lại chính nó với cursor kế tiếp) để không làm treo hàng chờ job nếu dữ liệu quá lớn.

## 7. Cấu hình & I18n
- **GlobalConfig**: Thêm App ID/Secret vào `GlobalConfigService`.
- **Translations**: Cập nhật `app/javascript/dashboard/i18n/locale/vi/integrations.json` và `en.json`.
- **Frontend**: Tạo component Vue cho việc cấu hình/kết nối trong `app/javascript/dashboard/routes/dashboard/settings/inbox/`.

---
> [!IMPORTANT]
> **Checklist quan trọng:**
> 1. Luôn mã hóa Token trong DB.
> 2. Luôn Verify Webhook Signature.
> 3. Hỗ trợ Echo Message để dữ liệu dashboard và app mobile luôn khớp nhau.
> 4. Metadata của tin nhắn nên lưu `source_id` để tránh tạo trùng tin nhắn (Idempotency).
