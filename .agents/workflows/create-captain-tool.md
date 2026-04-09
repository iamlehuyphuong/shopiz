---
description: Hướng dẫn tạo mới một công cụ (Tool) cho Captain AI
---

# Tài liệu Hướng dẫn Tạo mới Captain Tool

Tài liệu này quy định các tiêu chuẩn kỹ thuật và quy trình thực hiện khi phát triển một công cụ mới (Tool) cho hệ thống **Captain AI (V2)** trên nền tảng Shopiz.

## 1. Cấu trúc và Vị trí (Architecture & Location)

Các công cụ của Captain được chia thành hai loại chính:

| Loại Tool | Vị trí (Directory) | Lớp kế thừa (Base Class) |
| :--- | :--- | :--- |
| **Công cụ cốt lõi** | `enterprise/lib/captain/tools/` | `Captain::Tools::BasePublicTool` |
| **Công cụ tích hợp** | `enterprise/app/services/captain/tools/` | `Captain::Tools::BaseTool` |

Cả hai lớp cơ sở trên đều kế thừa từ `RubyLLM::Tool` (hoặc `Agents::Tool`), cung cấp DSL để định nghĩa tham số và mô tả công cụ cho LLM.

---

## 2. Quy trình Thực hiện chi tiết

### Bước 1: Khởi tạo File Công cụ
Tạo file mới tại thư mục tương ứng (ví dụ: `enterprise/lib/captain/tools/my_new_tool.rb`).
Tên class phải tuân theo quy tắc: `Captain::Tools::<PascalCase(tool_id)>Tool`.

### Bước 2: Định nghĩa Metadata (LLM Interface)
Sử dụng DSL để mô tả công cụ:
*   `description`: Mô tả rõ ràng về mục đích của công cụ để LLM biết khi nào nên gọi.
*   `param`: Định nghĩa các tham số đầu vào (tên, kiểu dữ liệu, mô tả).

### Bước 3: Triển khai Logic thực thi
Viết phương thức `perform(tool_context, **args)`:
*   `tool_context`: Chứa trạng thái hiện tại (`state`) như `conversation_id`, `contact_id`, v.v.
*   `**args`: Các tham số bạn đã định nghĩa ở Bước 2.
*   Giá trị trả về: Phải là một **String** để AI có thể đọc và hiểu kết quả.

### Bước 4: Đăng ký Công cụ (Registration)
Thêm tool vào file cấu hình `config/agents/tools.yml` để hệ thống tự động nhận diện và hiển thị trên giao diện Dashboard.

---

## 3. Checklist Logic bắt buộc

- [ ] **Class Naming**: Tên class phải khớp với ID (ví dụ: `id: send_sms` -> `class SendSmsTool`).
- [ ] **Inheritance**: Kế thừa đúng `BasePublicTool` hoặc `BaseTool`.
- [ ] **Param Validation**: Kiểm tra tính hợp lệ của tham số trong phương thức `perform`.
- [ ] **Context Usage**: Sử dụng `find_conversation(tool_context.state)` hoặc `find_contact(tool_context.state)` từ lớp cơ sở.
- [ ] **String Response**: Luôn trả về kết quả dưới dạng chuỗi mô tả (kể cả khi lỗi).
- [ ] **Usage Logging**: Sử dụng `log_tool_usage` để ghi lại lịch sử hoạt động.
- [ ] **Permissions**: (Tùy chọn) Ghi đè phương thức `permissions` nếu công cụ yêu cầu quyền cụ thể.
- [ ] **I18n**: Cập nhật file `en.yml` hoặc `vi.yml` nếu công cụ có hiển thị thông tin trên UI.

---

## 4. Ví dụ code chuẩn (Reference Implementation)

```ruby
# enterprise/lib/captain/tools/send_message_tool.rb
class Captain::Tools::SendMessageTool < Captain::Tools::BasePublicTool
  description 'Gửi tin nhắn văn bản cho khách hàng'
  param :content, type: 'string', desc: 'Nội dung tin nhắn cần gửi'

  def perform(tool_context, content:)
    conversation = find_conversation(tool_context.state)
    return 'Không tìm thấy cuộc trò chuyện' unless conversation

    # Logic gửi tin nhắn
    # ...
    
    log_tool_usage('send_message', { conversation_id: conversation.id })
    "Tin nhắn đã được gửi thành công đến hội thoại #{conversation.display_id}"
  end
end
```

---

> [!IMPORTANT]
> **Lưu ý quan trọng:** Không nên thực hiện các logic quá nặng hoặc tốn thời gian (Long-running tasks) trực tiếp trong `perform`. Nếu cần, hãy đẩy vào Sidekiq Job và trả về thông báo "Đang xử lý".

> [!TIP]
> **Mẹo:** Bạn có thể tham khảo `enterprise/lib/captain/tools/add_contact_note_tool.rb` để xem một ví dụ thực tế về cách thao tác với dữ liệu Contact.
