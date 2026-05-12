require 'yaml'

file_path = 'config/agents/tools.yml'
tools = YAML.load_file(file_path)

translations = {
  'faq_lookup' => { title: 'FAQ Lookup (Tra cứu FAQ)', desc: 'Search FAQ responses using semantic similarity (Tìm kiếm câu trả lời từ tài liệu tri thức bằng AI)' },
  'resolve_conversation' => { title: 'Resolve Conversation (Đóng hội thoại)', desc: 'Resolve a conversation when the issue has been addressed (Đánh dấu đóng hội thoại khi vấn đề đã được xử lý xong)' },
  'handoff' => { title: 'Handoff to Human (Chuyển cho nhân viên)', desc: 'Hand off the conversation to a human agent (Chuyển cuộc trò chuyện cho nhân viên hỗ trợ)' },
  'assign_conversation' => { title: 'Assign Conversation (Phân công hội thoại)', desc: 'Assign a conversation to a specific team or agent (Phân công hội thoại cho một nhóm hoặc nhân viên cụ thể)' },
  'update_contact' => { title: 'Update Contact (Cập nhật thông tin khách hàng)', desc: 'Update contact profile information (name, email, phone, custom attributes) (Cập nhật thông tin hồ sơ của khách hàng)' },
  'get_contact_detail' => { title: 'Get Contact Details (Xem chi tiết khách hàng)', desc: 'Get detailed information about the current contact (Lấy thông tin chi tiết về khách hàng hiện tại)' },
  'snooze_conversation' => { title: 'Snooze Conversation (Tạm hoãn hội thoại)', desc: 'Snooze a conversation to follow up later (Tạm hoãn cuộc hội thoại để xử lý sau)' },
  'remove_label_from_conversation' => { title: 'Remove Label (Gỡ nhãn hội thoại)', desc: 'Remove a label from a conversation (Gỡ bỏ một nhãn khỏi cuộc hội thoại)' },
  'set_conversation_custom_attribute' => { title: 'Set Custom Attributes (Cập nhật thuộc tính tùy chỉnh)', desc: 'Set or update custom attributes on a conversation (Cập nhật thông tin thuộc tính tùy chỉnh của hội thoại)' },
  'search_previous_conversation' => { title: 'Search Previous Conversations (Lịch sử trò chuyện)', desc: 'Search previous conversations of the current contact (Tra cứu lại các lịch sử hội thoại trước đó của khách)' }
}

tools.each do |tool|
  next if tool['hidden']
  
  translation = translations[tool['id']]
  if translation
    tool['title'] = translation[:title]
    tool['description'] = translation[:desc]
  end
end

File.write(file_path, tools.to_yaml)
puts "Updated remaining tools in tools.yml with bilingual texts."
