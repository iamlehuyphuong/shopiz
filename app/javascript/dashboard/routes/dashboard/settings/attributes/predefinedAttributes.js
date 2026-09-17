export const predefinedAttributes = {
  vi: {
    // 0 = Conversation Attribute
    0: [
      {
        attribute_display_name: 'Điểm hài lòng',
        attribute_key: 'csat_score',
        attribute_description: 'Điểm CSAT đánh giá mức độ hài lòng của khách hàng',
        attribute_display_type: 1, // NUMBER
        attribute_values: [],
      },
      {
        attribute_display_name: 'Kênh tiếp cận chiến dịch',
        attribute_key: 'campaign_channel',
        attribute_description: 'Kênh khách hàng tiếp cận chiến dịch tiếp thị',
        attribute_display_type: 6, // LIST
        attribute_values: ['Organic', 'Ads', 'Referral', 'KOL/KOC'],
      },
      {
        attribute_display_name: 'Mức độ rủi ro rời bỏ',
        attribute_key: 'churn_risk',
        attribute_description: 'Đánh giá nguy cơ khách hàng ngừng sử dụng dịch vụ',
        attribute_display_type: 6,
        attribute_values: ['Thấp', 'Trung bình', 'Cao'],
      },
      {
        attribute_display_name: 'Hướng xử lý khiếu nại',
        attribute_key: 'resolution_path',
        attribute_description: 'Cách giải quyết khiếu nại của khách hàng',
        attribute_display_type: 6,
        attribute_values: ['Hoàn tiền', 'Đổi mới', 'Sửa chữa', 'Xin lỗi/Tặng voucher', 'Chuyển cấp trên'],
      },
      {
        attribute_display_name: 'Khung giờ thuận tiện liên hệ',
        attribute_key: 'preferred_contact_time',
        attribute_description: 'Khung giờ khách hàng rảnh để nghe máy/nhắn tin',
        attribute_display_type: 6,
        attribute_values: ['Sáng (8h-12h)', 'Chiều (13h-17h)', 'Tối (18h-21h)'],
      },
    ],
    // 1 = Contact Attribute
    1: [
      {
        attribute_display_name: 'Hạng thành viên',
        attribute_key: 'vip_level',
        attribute_description: 'Mức độ VIP của khách hàng',
        attribute_display_type: 6, // LIST
        attribute_values: ['Thành viên', 'Bạc', 'Vàng', 'Bạch kim', 'Kim cương'],
      },
      {
        attribute_display_name: 'Nguồn khách hàng',
        attribute_key: 'customer_source',
        attribute_description: 'Kênh giới thiệu hoặc nguồn gốc khách hàng',
        attribute_display_type: 6,
        attribute_values: ['Facebook', 'Zalo', 'Website', 'TikTok', 'Giới thiệu', 'Sự kiện'],
      },
      {
        attribute_display_name: 'Sở thích',
        attribute_key: 'hobbies',
        attribute_description: 'Ghi chú về sở thích và quan tâm của khách hàng',
        attribute_display_type: 0, // TEXT
        attribute_values: [],
      },
      {
        attribute_display_name: 'Đặc điểm tính cách',
        attribute_key: 'personality',
        attribute_description: 'Quan sát về tính cách khách hàng để giao tiếp phù hợp',
        attribute_display_type: 0,
        attribute_values: [],
      },
      {
        attribute_display_name: 'Nhóm tính cách DISC',
        attribute_key: 'disc_profile',
        attribute_description: 'Phân loại nhóm tính cách theo biểu đồ DISC',
        attribute_display_type: 6,
        attribute_values: ['D (Thống trị)', 'I (Ảnh hưởng)', 'S (Kiên định)', 'C (Tuân thủ)'],
      },
      {
        attribute_display_name: 'Nghề nghiệp',
        attribute_key: 'occupation',
        attribute_description: 'Công việc hiện tại của khách hàng',
        attribute_display_type: 0,
        attribute_values: [],
      },
      {
        attribute_display_name: 'Tình trạng hôn nhân',
        attribute_key: 'marital_status',
        attribute_description: 'Tình trạng hôn nhân gia đình',
        attribute_display_type: 6,
        attribute_values: ['Độc thân', 'Đã kết hôn', 'Khác'],
      },
    ],
  },
  en: {
    // 0 = Conversation Attribute
    0: [
      {
        attribute_display_name: 'CSAT Score',
        attribute_key: 'csat_score',
        attribute_description: 'Customer satisfaction score for this conversation',
        attribute_display_type: 1, // NUMBER
        attribute_values: [],
      },
      {
        attribute_display_name: 'Campaign Channel',
        attribute_key: 'campaign_channel',
        attribute_description: 'Channel through which the customer was acquired',
        attribute_display_type: 6, // LIST
        attribute_values: ['Organic', 'Ads', 'Referral', 'KOL/KOC'],
      },
      {
        attribute_display_name: 'Churn Risk',
        attribute_key: 'churn_risk',
        attribute_description: 'Assessed risk of customer churning',
        attribute_display_type: 6,
        attribute_values: ['Low', 'Medium', 'High'],
      },
      {
        attribute_display_name: 'Resolution Path',
        attribute_key: 'resolution_path',
        attribute_description: 'How the customer complaint was resolved',
        attribute_display_type: 6,
        attribute_values: ['Refund', 'Replace', 'Repair', 'Apologize/Voucher', 'Escalate'],
      },
      {
        attribute_display_name: 'Preferred Contact Time',
        attribute_key: 'preferred_contact_time',
        attribute_description: 'Best time frame to contact the customer',
        attribute_display_type: 6,
        attribute_values: ['Morning (8AM-12PM)', 'Afternoon (1PM-5PM)', 'Evening (6PM-9PM)'],
      },
    ],
    // 1 = Contact Attribute
    1: [
      {
        attribute_display_name: 'VIP Level',
        attribute_key: 'vip_level',
        attribute_description: 'Customer VIP tier',
        attribute_display_type: 6, // LIST
        attribute_values: ['Member', 'Silver', 'Gold', 'Platinum', 'Diamond'],
      },
      {
        attribute_display_name: 'Customer Source',
        attribute_key: 'customer_source',
        attribute_description: 'Where the customer originated from',
        attribute_display_type: 6,
        attribute_values: ['Facebook', 'WhatsApp', 'Website', 'TikTok', 'Referral', 'Event'],
      },
      {
        attribute_display_name: 'Hobbies/Interests',
        attribute_key: 'hobbies',
        attribute_description: 'Notes on customer hobbies and interests',
        attribute_display_type: 0, // TEXT
        attribute_values: [],
      },
      {
        attribute_display_name: 'Personality',
        attribute_key: 'personality',
        attribute_description: 'Observations on customer personality for communication',
        attribute_display_type: 0,
        attribute_values: [],
      },
      {
        attribute_display_name: 'DISC Profile',
        attribute_key: 'disc_profile',
        attribute_description: 'DISC personality assessment',
        attribute_display_type: 6,
        attribute_values: ['D (Dominance)', 'I (Influence)', 'S (Steadiness)', 'C (Compliance)'],
      },
      {
        attribute_display_name: 'Occupation',
        attribute_key: 'occupation',
        attribute_description: 'Current job or profession',
        attribute_display_type: 0,
        attribute_values: [],
      },
      {
        attribute_display_name: 'Marital Status',
        attribute_key: 'marital_status',
        attribute_description: 'Marital or relationship status',
        attribute_display_type: 6,
        attribute_values: ['Single', 'Married', 'Other'],
      },
    ],
  },
};
