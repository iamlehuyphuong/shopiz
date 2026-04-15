---
description: Hướng dẫn tổng quan tạo mới một công cụ (Tool) cho Captain AI. Xem thêm workflow chi tiết cho từng loại tool.
---

# Tạo mới Captain Tool — Tổng quan

## 1. Phân loại Công cụ

| Loại | Vị trí | Base Class | Method | Workflow chi tiết |
| :--- | :--- | :--- | :--- | :--- |
| **Public Tool** | `enterprise/lib/captain/tools/` | `BasePublicTool` → `Agents::Tool` | `perform(tool_context, **args)` | `/create-captain-public-tool` |
| **Copilot Tool** | `enterprise/app/services/captain/tools/copilot/` | `BaseTool` → `RubyLLM::Tool` | `execute(**args)` | `/create-captain-copilot-tool` |
| **Custom HTTP Tool** | DB `captain_custom_tools` | `HttpTool` → `Agents::Tool` | Tự động qua `Concerns::Toolable` | Tạo qua Dashboard, không cần code |

## 2. Chuỗi kế thừa

```
Agents::Tool (gem 'ai-agents')
├── Captain::Tools::BasePublicTool
│   ├── AddContactNoteTool
│   ├── AddPrivateNoteTool
│   ├── AddLabelToConversationTool
│   ├── AddInteractiveMessageToConversationTool
│   ├── FaqLookupTool
│   ├── HandoffTool
│   ├── ResolveConversationTool
│   └── UpdatePriorityTool
└── Captain::Tools::HttpTool (cho Custom Tools)

RubyLLM::Tool
└── Captain::Tools::BaseTool (prepend Instrumentation)
    └── Copilot::*Service (7 tools)
```

## 3. Luồng đăng ký & khởi tạo

1. **Public Tools** đăng ký trong `config/agents/tools.yml` → `CaptainToolsHelpers.load_agent_tools` resolve class qua `tool_id.classify + "Tool"` → `safe_constantize`
2. **Copilot Tools** đăng ký riêng trong copilot flow, KHÔNG cần YAML
3. **Custom HTTP Tools** lưu trong DB (`Captain::CustomTool`), tự động tạo class qua `Concerns::Toolable`
4. `Captain::Assistant#agent_tools` luôn load mặc định: `FaqLookupTool` + `HandoffTool`
5. `Captain::Scenario` tham chiếu tool bằng cú pháp `[Tool Name](tool://tool_id)`

## 4. So sánh nhanh Public vs Copilot

| Đặc điểm | Public Tool | Copilot Tool |
| :--- | :--- | :--- |
| Phương thức | `perform(tool_context, **args)` | `execute(**args)` |
| Truy cập context | `tool_context.state` | Không có |
| Permission | Override method `permissions` | Override `active?` + `user_has_permission` |
| `self.name` | Không cần | **Bắt buộc** |
| Instrumentation | Không tự động | Tự động (`prepend`) |
| Đăng ký YAML | **Có** | **Không** |
| Param type syntax | `type: 'string'` (string) | `type: :string` (symbol) |

## 5. Lưu ý chung

> [!IMPORTANT]
> Không thực hiện logic nặng trong `perform`/`execute`. Nếu cần, đẩy vào Sidekiq Job và trả về "Đang xử lý".

> [!NOTE]
> **Scenario & Tool References**: Trong `Captain::Scenario`, tool được tham chiếu bằng `[Tool Name](tool://tool_id)`. Hệ thống tự parse và resolve qua `resolve_tool_references`.
