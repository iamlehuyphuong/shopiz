---
description: Hướng dẫn chi tiết tạo Copilot Tool cho Captain AI (hỗ trợ agent nội bộ)
---

# Tạo Captain Copilot Tool

Copilot Tool là công cụ cho AI copilot hỗ trợ agent nội bộ (không tương tác trực tiếp với khách hàng).

## 1. Base Class: `BaseTool`

**File:** `enterprise/app/services/captain/tools/base_tool.rb`
**Kế thừa:** `RubyLLM::Tool`

```ruby
class Captain::Tools::BaseTool < RubyLLM::Tool
  prepend Captain::Tools::Instrumentation  # Auto-instrument execute calls

  def initialize(assistant, user: nil)     # Nhận assistant + user
  def active?                              # Luôn true, override để check permission

  # Private helpers:
  def user_has_permission(permission)      # Check quyền qua AccountUser
end
```

**Điểm khác biệt so với Public Tool:**
- Phương thức: `execute(**args)` (KHÔNG phải `perform`)
- Không có `tool_context` — truy cập data qua `@assistant`
- Bắt buộc override `def self.name`
- Permission check qua `active?` + `user_has_permission`
- Tự động instrumentation qua `prepend`
- **Không** đăng ký trong `config/agents/tools.yml`
- Param type dùng symbol: `type: :string` (không phải `'string'`)

## 2. Quy trình từng bước

### Bước 1: Tạo file

Tại `enterprise/app/services/captain/tools/copilot/<tool_name>_service.rb`.
Quy tắc: `Captain::Tools::Copilot::<ToolName>Service`.

### Bước 2: Override `self.name`

```ruby
def self.name
  'my_tool_name'  # Tên tool gửi tới LLM API — bắt buộc!
end
```

### Bước 3: Định nghĩa metadata (DSL)

```ruby
description 'Mô tả công cụ cho LLM'

param :param1, type: :string, desc: 'Mô tả param'
param :param2, type: :number, desc: 'Tùy chọn', required: false
```

**Type hỗ trợ:** `:string`, `:number`, `:integer`, `:boolean` — mặc định `required: true`.

### Bước 4: Triển khai `execute`

```ruby
def execute(param1:, param2: nil)
  # 1. Query dữ liệu (scope theo account)
  records = Model.where(account_id: @assistant.account_id)

  # 2. Filter / logic
  records = records.where(field: param1) if param1.present?

  # 3. Return String
  return 'No results found' unless records.exists?

  records = records.limit(100)
  <<~RESPONSE
    #{records.map(&:to_llm_text).join("\n---\n")}
  RESPONSE
end
```

### Bước 5: Override `active?` (Permission check)

```ruby
def active?
  user_has_permission('conversation_manage') ||
    user_has_permission('conversation_unassigned_manage')
end
```

Permissions phổ biến: `conversation_manage`, `conversation_unassigned_manage`, `conversation_participating_manage`, `contact_manage`.

### Bước 6: Cập nhật I18n (nếu cần)

Chỉ khi tool có hiển thị thông tin trên UI.

## 3. Checklist

- [ ] Class: `Captain::Tools::Copilot::{ToolName}Service`
- [ ] Kế thừa `Captain::Tools::BaseTool`
- [ ] File tại `enterprise/app/services/captain/tools/copilot/<name>_service.rb`
- [ ] Override `def self.name` (bắt buộc)
- [ ] Dùng `def execute(**args)` (KHÔNG phải `perform`)
- [ ] Override `active?` với `user_has_permission`
- [ ] Luôn trả về `String`
- [ ] Scope dữ liệu theo `@assistant.account_id`
- [ ] Limit kết quả (thường `limit(100)`) để tránh token overflow

## 4. Ví dụ thực tế

### Tool tìm kiếm

```ruby
# enterprise/app/services/captain/tools/copilot/search_contacts_service.rb
class Captain::Tools::Copilot::SearchContactsService < Captain::Tools::BaseTool
  def self.name
    'search_contacts'
  end

  description 'Search contacts based on query parameters'
  param :email, type: :string, desc: 'Filter contacts by email'
  param :phone_number, type: :string, desc: 'Filter contacts by phone number'
  param :name, type: :string, desc: 'Filter contacts by name (partial match)'

  def execute(email: nil, phone_number: nil, name: nil)
    contacts = Contact.where(account_id: @assistant.account_id)
    contacts = contacts.where(email: email) if email.present?
    contacts = contacts.where(phone_number: phone_number) if phone_number.present?
    contacts = contacts.where('LOWER(name) ILIKE ?', "%#{name.downcase}%") if name.present?

    return 'No contacts found' unless contacts.exists?

    contacts = contacts.limit(100)
    <<~RESPONSE
      #{contacts.map(&:to_llm_text).join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('contact_manage')
  end
end
```

### Tool lấy chi tiết

```ruby
# enterprise/app/services/captain/tools/copilot/get_conversation_service.rb
class Captain::Tools::Copilot::GetConversationService < Captain::Tools::BaseTool
  def self.name
    'get_conversation'
  end

  description 'Get details of a conversation including messages and contact information'
  param :conversation_id, type: :integer, desc: 'ID of the conversation', required: true

  def execute(conversation_id:)
    conversation = Conversation.find_by(
      display_id: conversation_id,
      account_id: @assistant.account_id
    )
    return 'Conversation not found' if conversation.blank?

    conversation.to_llm_text(include_private_messages: true)
  end

  def active?
    user_has_permission('conversation_manage') ||
      user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end
```

## 5. Danh sách Copilot Tools hiện có

| Tool Name | Class | Mô tả |
|-----------|-------|--------|
| `get_conversation` | `GetConversationService` | Chi tiết conversation + messages |
| `get_contact` | `GetContactService` | Thông tin contact |
| `get_article` | `GetArticleService` | Nội dung article |
| `search_conversation` | `SearchConversationsService` | Tìm conversation |
| `search_contacts` | `SearchContactsService` | Tìm contact |
| `search_articles` | `SearchArticlesService` | Tìm articles |
| `search_linear_issues` | `SearchLinearIssuesService` | Tìm Linear issues |
