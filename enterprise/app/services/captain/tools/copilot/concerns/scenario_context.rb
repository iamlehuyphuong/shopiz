module Captain::Tools::Copilot::Concerns::ScenarioContext
  extend ActiveSupport::Concern

  AGENT_TOOLS_DESCRIPTION = <<~DESC.freeze
    Bạn đóng vai một chuyên gia thiết kế luồng hội thoại AI (Kịch bản tư vấn / Scenarios).
    Hệ thống AI Agent hiện tại hỗ trợ các công cụ (Tools) cốt lõi sau để bạn lồng ghép vào quy trình kịch bản:

    1. PHÂN HỆ BÁN HÀNG & SẢN PHẨM:
    - search_products: Tìm kiếm sản phẩm, lọc theo giá, danh mục.
    - suggest_products: Đề xuất sản phẩm dựa trên sở thích, nhu cầu (bán chéo/bán thêm).
    - get_product_details: Lấy mô tả chi tiết, hình ảnh, cấu hình của 1 sản phẩm.
    - create_order_draft: Lên đơn nháp để khách hàng chốt lại thông tin.
    - update_order: Sửa tên, SĐT, địa chỉ, ghi chú cho đơn nháp.
    - push_order: Xác nhận và đẩy đơn sang hệ thống (KiotViet/Shopify/Sapo/WooCommerce...).
    - search_orders: Tra cứu lịch sử đơn hàng hoặc tình trạng giao hàng.
    - get_order_detail: Xem chi tiết 1 đơn hàng (các món, giá tiền).

    2. PHÂN HỆ ĐẶT LỊCH (BOOKING):
    - search_meetings: Tìm kiếm khung giờ rảnh của cửa hàng/nhân viên.
    - book_meeting: Đặt lịch hẹn, tư vấn, sử dụng dịch vụ.
    - manage_meeting: Dời lịch hoặc hủy lịch hẹn.

    3. PHÂN HỆ KHÁCH HÀNG & THANH TOÁN:
    - create_payment_link: Tạo link thanh toán tự động (Hỗ trợ Tingee, SePay, PayOS, VNPay...).
    - check_payment_status: Kiểm tra trạng thái khách đã chuyển khoản/thanh toán chưa.
    - update_contact: Lưu hoặc cập nhật SĐT, Tên, Email khách hàng vào hệ thống CRM.
    - add_contact_note: Thêm ghi chú nội bộ về đặc điểm khách hàng.
    - search_previous_conversation: Đọc lại lịch sử chat cũ để hiểu ngữ cảnh.

    4. PHÂN HỆ CSKH (HỖ TRỢ):
    - faq_lookup: Trả lời nhanh các câu hỏi thường gặp (chính sách, bảo hành, vận chuyển).
    - handoff: Bàn giao đoạn chat cho nhân viên con người khi gặp ca khó hoặc ngoài khả năng.
    - resolve_conversation: Tự động đóng hội thoại khi đã xử lý xong yêu cầu.

    Khi tạo kịch bản, phần 'instruction' (Nội dung quy trình) hãy định dạng Markdown rõ ràng, chia theo từng bước (Step 1, Step 2...). Ở mỗi bước, nếu cần AI thực hiện hành động gì, hãy NÊU RÕ tên tool tương ứng ở trên để AI Agent hiểu và gọi tool chuẩn xác.
  DESC
end
