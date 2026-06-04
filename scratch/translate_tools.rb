require 'yaml'

file_path = 'config/agents/tools.yml'
tools = YAML.load_file(file_path)

translations = {
  'add_contact_note' => { title: 'Add Contact Note (Thêm ghi chú khách hàng)', desc: 'Add a note to a contact profile (Thêm ghi chú vào hồ sơ khách hàng)' },
  'add_private_note' => { title: 'Add Private Note (Thêm ghi chú nội bộ)', desc: 'Add a private note to a conversation [internal only] (Thêm ghi chú nội bộ vào cuộc hội thoại)' },
  'update_priority' => { title: 'Update Priority (Cập nhật độ ưu tiên)', desc: 'Update conversation priority level (Cập nhật mức độ ưu tiên của hội thoại)' },
  'add_label_to_conversation' => { title: 'Add Label (Gắn nhãn hội thoại)', desc: 'Add a label to a conversation (Gắn một nhãn vào cuộc hội thoại)' },
  'add_interactive_message_to_conversation' => { title: 'Send Interactive Message (Gửi tin nhắn tương tác)', desc: 'Add an interactive message to a conversation (Gửi một tin nhắn tương tác như Nút bấm/Danh sách vào cuộc hội thoại)' },
  'search_help_center_articles' => { title: 'Search Help Center (Tìm bài viết hướng dẫn)', desc: 'Search help center articles by query (Tìm kiếm các bài viết hướng dẫn, tài liệu theo từ khóa)' },
  'get_help_center_article' => { title: 'Get Article Details (Xem chi tiết bài viết)', desc: 'Get the full details of a help center article by ID (Lấy nội dung chi tiết của một bài viết hướng dẫn)' },
  'search_products' => { title: 'Search Products (Tìm kiếm sản phẩm)', desc: 'Search products by keyword (auto-routes to connected e-commerce platform, or searches internal store) (Tìm kiếm sản phẩm theo từ khóa - tự động điều hướng tới nền tảng kết nối)' },
  'get_product_details' => { title: 'Get Product Details (Lấy chi tiết sản phẩm)', desc: 'Retrieve detailed product information (auto-routes to connected e-commerce platform, or searches internal store) (Lấy thông tin chi tiết và phân loại của sản phẩm)' },
  'search_orders' => { title: 'Search Orders (Tra cứu đơn hàng)', desc: 'Check order status and details (auto-routes to connected e-commerce platform, or searches internal orders) (Kiểm tra trạng thái và thông tin chi tiết đơn hàng)' },
  'suggest_products' => { title: 'Suggest Products (Gợi ý sản phẩm)', desc: 'Suggest upsell and cross-sell products based on current product selection (auto-routes to connected e-commerce platform) (Gợi ý các sản phẩm bán chéo, bán thêm dựa trên ngữ cảnh)' },
  'create_order_draft' => { title: 'Create Order Draft (Tạo đơn hàng nháp)', desc: 'Create a draft order for the current contact (auto-routes to connected e-commerce platform) (Tạo đơn hàng nháp cho khách hàng hiện tại)' },
  'get_canned_response' => { title: 'Get Canned Response (Lấy câu trả lời mẫu)', desc: 'Search and retrieve a canned response (saved template) by its short code or keywords (Tìm và lấy nội dung câu trả lời mẫu đã được soạn sẵn)' },
  'execute_macro' => { title: 'Execute Macro (Chạy kịch bản tự động)', desc: 'Execute an automation macro on the current conversation (Kích hoạt chạy một kịch bản tự động/Macro trên cuộc hội thoại hiện tại)' }
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
puts "Updated tools.yml with bilingual titles and descriptions."
