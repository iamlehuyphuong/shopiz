---
description: Hướng dẫn chi tiết tạo Public Tool (công cụ cốt lõi) cho Captain AI
---

# Tạo Captain Public Tool

Public Tool là công cụ built-in cho AI agent tương tác trực tiếp với khách hàng.

## 1. Base Class: `BasePublicTool`

**File:** `enterprise/lib/captain/tools/base_public_tool.rb`
**Kế thừa:** `Agents::Tool` (gem `ai-agents >= 0.9.1`)

```ruby
class Captain::Tools::BasePublicTool < Agents::Tool
  def initialize(assistant)     # Lưu @assistant
  def active?                   # Luôn true
  def permissions               # Override để yêu cầu quyền, mặc định []

  # Private helpers:
  def account_scoped(model_class)         # Scope theo @assistant.account_id
  def find_conversation(state)            # Tìm từ state[:conversation][:id]
  def find_contact(state)                 # Tìm từ state[:contact][:id]
  def log_tool_usage(action, details={})  # Rails.logger.info
end
```

## 2. Quy trình từng bước

### Bước 1: Tạo file

Tại `enterprise/lib/captain/tools/<tool_id>_tool.rb`.
Quy tắc đặt tên: `Captain::Tools::<PascalCase(tool_id)>Tool`.

### Bước 2: Định nghĩa metadata (DSL)

```ruby
description 'Mô tả rõ ràng mục đích - AI dùng để quyết định khi nào gọi tool'

param :param_name, type: 'string', desc: 'Mô tả tham số cho AI'
param :optional_param, type: 'string', desc: 'Tùy chọn', required: false
```

**Type hỗ trợ:** `'string'`, `'number'`, `'integer'`, `'boolean'` — mặc định `required: true`.

### Bước 3: Triển khai `perform`

```ruby
def perform(tool_context, param_name:, optional_param: nil)
  # 1. Lấy entity
  conversation = find_conversation(tool_context.state)
  return 'Conversation not found' unless conversation

  # 2. Validate
  return 'Param is required' if param_name.blank?

  # 3. Log
  log_tool_usage('action_name', { conversation_id: conversation.id })

  # 4. Logic nghiệp vụ ...

  # 5. Return String
  "Done for conversation ##{conversation.display_id}"
rescue StandardError => e
  ChatwootExceptionTracker.new(e).capture_exception
  'Failed to perform action'
end
```

**`tool_context.state` chứa:** `conversation: { id: }`, `contact: { id:, email:, phone_number: }`, `account_id:`, `assistant_id:`, `assistant_config:`, `contact_inbox: { id:, hmac_verified: }`, `campaign: {}`.

### Bước 4: (Tùy chọn) Khai báo `permissions`

```ruby
private

def permissions
  %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
end
```

Permissions phổ biến: `conversation_manage`, `conversation_unassigned_manage`, `conversation_participating_manage`, `contact_manage`.

### Bước 5: Đăng ký trong YAML

Thêm vào `config/agents/tools.yml`:

```yaml
- id: send_sms              # snake_case, khớp tên class (bỏ "Tool")
  title: 'Send SMS'         # Hiển thị trên Dashboard
  description: 'Send SMS'   # Mô tả Dashboard
  icon: 'message-square'    # Icon frontend
```

> [!IMPORTANT]
> `id` phải khớp class: `id: send_sms` → `Captain::Tools::SendSmsTool` (dùng `tool_id.classify + "Tool"`).

### Bước 6: Cập nhật I18n (nếu cần)

- Backend: `config/locales/en.yml` / `vi.yml`
- Frontend: `app/javascript/dashboard/i18n/locale/en/*.json`

## 3. Checklist

- [ ] Class đặt tên đúng: `Captain::Tools::{classify(id)}Tool`
- [ ] Kế thừa `Captain::Tools::BasePublicTool`
- [ ] File tại `enterprise/lib/captain/tools/<id>_tool.rb`
- [ ] Signature: `def perform(tool_context, **named_args)`
- [ ] Dùng `find_conversation` / `find_contact` / `account_scoped`
- [ ] Luôn trả về `String`
- [ ] Gọi `log_tool_usage`
- [ ] `rescue StandardError` + `ChatwootExceptionTracker` cho tool có side-effects
- [ ] Override `permissions` nếu cần
- [ ] Đăng ký `config/agents/tools.yml`
- [ ] I18n (nếu hiển thị UI)

## 4. Ví dụ thực tế

### Tool đơn giản (CRUD)

```ruby
# enterprise/lib/captain/tools/add_contact_note_tool.rb
class Captain::Tools::AddContactNoteTool < Captain::Tools::BasePublicTool
  description 'Add a note to a contact profile'
  param :note, type: 'string', desc: 'The note content to add to the contact'

  def perform(tool_context, note:)
    contact = find_contact(tool_context.state)
    return 'Contact not found' unless contact
    return 'Note content is required' if note.blank?

    log_tool_usage('add_contact_note', { contact_id: contact.id, note_length: note.length })
    contact.notes.create!(content: note)
    "Note added successfully to contact #{contact.name} (ID: #{contact.id})"
  end

  private

  def permissions
    %w[contact_manage]
  end
end
```

### Tool phức tạp (Side-effects + Error handling)

```ruby
# enterprise/lib/captain/tools/handoff_tool.rb
class Captain::Tools::HandoffTool < Captain::Tools::BasePublicTool
  description 'Hand off the conversation to a human agent'
  param :reason, type: 'string', desc: 'Reason for handoff', required: false

  def perform(tool_context, reason: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    log_tool_usage('tool_handoff', {
      conversation_id: conversation.id,
      reason: reason || 'Agent requested handoff'
    })

    conversation.messages.create!(
      message_type: :outgoing, private: true,
      sender: @assistant, account: conversation.account,
      inbox: conversation.inbox, content: reason
    )
    conversation.bot_handoff!

    "Conversation handed off#{" (Reason: #{reason})" if reason}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to handoff conversation'
  end
end
```
