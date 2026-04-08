---
description: Hướng dẫn tích hợp kênh mới
---

# Tài liệu Hướng dẫn Tích hợp Kênh mới (Standard Channel Integration)

Tài liệu này quy định các tiêu chuẩn kỹ thuật và các đầu mục công việc bắt buộc khi phát triển một tích hợp kênh (Inbox Channel) mới trên nền tảng Shopiz.

## 1. Kiến trúc Hệ thống (System Architecture)

Hệ thống tích hợp kênh được chia thành 4 lớp xử lý chính:

| Lớp (Layer) | Thành phần chính | Nhiệm vụ |
| :--- | :--- | :--- |
| **Data Layer** | `Channel::<Name>` | Model kế thừa `Channelable`, lưu trữ thông tin kết nối và Credentials. |
| **Logic Layer** | `app/services/<name>/` | Chứa `Client` (API wrapper), `TokenService` (Auth), và `MessageService`. |
| **Inbound Layer** | `Webhooks Controller` | Nhận Webhook, kiểm tra bảo mật và đẩy vào hàng chờ (Job). |
| **Outbound Layer** | `SendOnService` | Xử lý việc gửi tin nhắn từ dashboard ngược về nhà cung cấp. |

---

## 2. Quy trình Thực hiện chi tiết

### Bước 1: Khởi tạo Database & Model
*   Tạo migration: `bin/rails g migration CreateChannel<Name>`.
*   Cấu hình Model tại `app/models/channel/<name.rb>`:
    *   Include các module core: `Channelable`, `Reauthorizable`.
    *   Sử dụng `encrypts` cho các trường `access_token`, `refresh_token`.

### Bước 2: Xây dựng Bộ Dịch vụ Logic (Services)
*   **AuthClient**: Xử lý luồng lấy mã (OAuth) và trao đổi Token.
*   **TokenService**: Quản lý vòng đời Token (Refresh tự động, dùng Redis Lock).
*   **Client**: Wrapper cho các API (Send, Upload, Download, Profile).

### Bước 3: Xử lý Luồng Tin nhắn Inbound (Webhook)
*   **Controller**: `app/controllers/webhooks/<name>_controller.rb`. Phải Verify Signature trước khi xử lý.
*   **Job**: `app/jobs/webhooks/<name>_events_job.rb`. Sử dụng `MutexApplicationJob` với key là `conversation_id`.
*   **MessageService**: Parsing payload thô → Tạo Contact → Tạo Conversation → Tạo Message.

### Bước 4: Xử lý Đồng bộ Lịch sử (Sync Task)
*   **SyncJob**: Chạy ngầm sau khi kết nối thành công để lấy danh sách hội thoại và tin nhắn cũ, đảm bảo nhân viên có đủ ngữ cảnh (context).

---

## 3. Checklist Logic bắt buộc (Full Checklist)

Bạn cần hoàn thành tất cả các mục dưới đây để đảm bảo một tích hợp kênh đạt chuẩn:

### 🛡️ Bảo mật & Xác thực (Security)
- [ ] **Webhook Verification**: Kiểm tra chữ ký (Signature) từ Header của nhà cung cấp.
- [ ] **Credential Encryption**: Mã hóa Access Token và Refresh Token trong Database.
- [ ] **Config Encryption**: Lưu App ID/Secret trong `GlobalConfigService` thay vì hardcode.

### 👥 Quản lý Hội thoại (Conversation & Contact)
- [ ] **Contact Builder**: Tìm kiếm contact qua `social_id` hoặc tạo mới (kèm Avatar/Name).
- [ ] **Conversation Linking**: Gán tin vào conversation hiện tại hoặc tự động mở lại nếu đã Resolve.
- [ ] **Social Profiles**: Lưu thông tin `additional_attributes` (Username, UserID) cho Contact.

### 💬 Logic Message & Media
- [ ] **Echo Support**: Xử lý tin nhắn "vọng" gửi từ app mobile của nhà cung cấp để đồng bộ về Shopiz.
- [ ] **Deduplication**: Sử dụng `source_id` của nhà cung cấp để tránh trùng lặp tin nhắn.
- [ ] **Attachment Handler**: Download ảnh/file từ nhà cung cấp về ActiveStorage của hệ thống.
- [ ] **Unsupported Types**: Ghi nhận các loại tin nhắn chưa hỗ trợ dưới dạng `is_unsupported: true`.

### 🔄 Đồng bộ Lịch sử (Historical Sync)
- [ ] **Conversation Backfill**: Tải danh sách hội thoại gần đây khi lần đầu kết nối.
- [ ] **Message History**: Lấy 20-50 tin nhắn cũ nhất trong mỗi hội thoại để có context.
- [ ] **Batch Processing**: Chia nhỏ việc đồng bộ thành các Job nhỏ, tránh bị API Rate Limit.
- [ ] **Progress Notification**: Thông báo trạng thái đồng bộ dữ liệu cho người dùng cuối.

### ⚙️ Vận hành & UX (Frontend/Backend)
- [ ] **Token Auto-Refresh**: Logic tự động refresh token 30 phút trước khi hết hạn.
- [ ] **I18n (Internationalization)**: Đầy đủ nhãn Tiếng Anh/Tiếng Việt cho kênh mới.
- [ ] **Setup Wizard**: Giao diện hướng dẫn người dùng kết nối (Nút Login, Hướng dẫn lấy Token).

---

> [!IMPORTANT]
> **Best Practice cho Đồng bộ (Sync):** 
> Luôn sử dụng `Recursive Job` (Job tự trigger lại chính nó với cursor mới) nếu dữ liệu quá lớn. Điều này giúp hệ thống không bị "nghẽn" hàng chờ và dễ dàng phục hồi (Retry) nếu gặp lỗi giữa chừng.

> [!TIP]
> **Mẹo nhỏ:** Bạn có thể tham khảo trực tiếp logic xử lý Attachment tại `app/services/zalo/messaging_helpers.rb` hoặc `app/services/tiktok/client.rb` để áp dụng cho kênh mới.