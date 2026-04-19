require 'fileutils'

DIVIDER = "<hr style=\"border: 0; border-bottom: 1px solid #E2E8F0; margin: 24px 0;\" />"

TEMPLATE_MAPPINGS = {
  "app/views/mailers/team_notifications/automation_notification_mailer/message_created.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">New Message</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      A new message was recorded in the conversation monitored by your automation rules.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      <strong>Customer:</strong> {{ conversation.contact_name }}<br/>
      <strong>Message:</strong> {{ message.text_content }}
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">View Conversation</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Tin Nhắn Mới</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Có một tin nhắn mới được ghi nhận trong hộp thoại mà tự động hoá đang theo dõi.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      <strong>Khách hàng:</strong> {{ conversation.contact_name }}<br/>
      <strong>Tin nhắn:</strong> {{ message.text_content }}
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Xem Cuộc Trò Chuyện</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/team_notifications/automation_notification_mailer/conversation_updated.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Conversation Updated</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      The conversation with customer <strong>{{ conversation.contact_name }}</strong> has been updated (new assignment, status change, or labels modified).
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">View Details</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Cuộc Trò Chuyện Được Cập Nhật</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Cuộc trò chuyện của khách hàng <strong>{{ conversation.contact_name }}</strong> vừa được cập nhật (phân công mới, đổi trạng thái hoặc thay đổi tag).
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Xem Chi Tiết</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/team_notifications/automation_notification_mailer/conversation_creation.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">New Conversation</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      A new conversation was just created and triggered a system automation rule.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Open Conversation</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Cuộc Trò Chuyện Mới</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Một cuộc trò chuyện mới vừa được tạo và kích hoạt quy tắc tự động hóa của hệ thống.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Mở Cuộc Trò Chuyện</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/agent_notifications/conversation_notifications_mailer/sla_missed_resolution.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Resolution SLA Missed</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      The conversation with <strong>{{ conversation.contact_name }}</strong> (ID: \\\#{{ conversation.display_id }}) has missed the <strong>resolution</strong> SLA target.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #EF4444; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Resolve Immediately</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Vi Phạm SLA Độ Trễ Xử Lý</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Cuộc trò chuyện với khách hàng <strong>{{ conversation.contact_name }}</strong> (Mã: \\\#{{ conversation.display_id }}) đã vi phạm chính sách SLA về thời gian <strong>giải quyết dứt điểm</strong>.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #EF4444; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Xử Lý Khẩn Cấp</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/agent_notifications/conversation_notifications_mailer/conversation_mention.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">You Were Mentioned</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      You've been mentioned in an internal note for conversation \\\#{{ conversation.display_id }}.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      <strong>Note:</strong> {{ message.text_content }}
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">View Conversation</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Bạn Vừa Được Nhắc Đến</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Bạn vừa được nhắc đến (mention) trong hộp thoại nội bộ của cuộc trò chuyện \\\#{{ conversation.display_id }}.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      <strong>Tin nhắn nội bộ:</strong> {{ message.text_content }}
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Xem Cuộc Trò Chuyện</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/agent_notifications/conversation_notifications_mailer/sla_missed_first_response.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">First Response SLA Missed</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      The conversation with <strong>{{ conversation.contact_name }}</strong> (ID: \\\#{{ conversation.display_id }}) has missed the <strong>first response</strong> SLA target.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #EF4444; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Reply Immediately</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Vi Phạm SLA Phản Hồi Đầu Tiên</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Cuộc trò chuyện với khách hàng <strong>{{ conversation.contact_name }}</strong> (Mã: \\\#{{ conversation.display_id }}) đã vượt quá thời gian cam kết <strong>trả lời lần đầu tiên</strong>.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #EF4444; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Trả Lời Ngay Khách</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/agent_notifications/conversation_notifications_mailer/conversation_assignment.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">New Conversation Assigned</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      A conversation with <strong>{{ conversation.contact_name }}</strong> (ID: \\\#{{ conversation.display_id }}) has just been assigned to you.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Open Conversation</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Bạn Có Cuộc Trò Chuyện Mới</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Cuộc trò chuyện từ khách hàng <strong>{{ conversation.contact_name }}</strong> (Mã: \\\#{{ conversation.display_id }}) vừa được phân công cho bạn.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Mở Hộp Thoại</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/agent_notifications/conversation_notifications_mailer/participating_conversation_new_message.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">New Message in Participating Conversation</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      There is a new message in a conversation that you are participating in.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">View Update</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Tin Nhắn Mới - Hội Thoại Cùng Tham Gia</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Có thông tin phản hồi mới từ cuộc trò chuyện mà bạn đang đánh dấu theo dõi hoặc cùng tham gia.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Xem Cập Nhật</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/agent_notifications/conversation_notifications_mailer/sla_missed_next_response.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Next Response SLA Missed</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      The customer <strong>{{ conversation.contact_name }}</strong> has been waiting too long for a subsequent response. The next-response SLA was missed.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #EF4444; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Reply Immediately</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Vi Phạm SLA Phản Hồi Tiếp Theo</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Khách hàng <strong>{{ conversation.contact_name }}</strong> đã chờ quá lâu để bạn hồi âm lại tin nhắn tiếp theo của họ.
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #EF4444; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Trả Lời Ngay Khách</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/agent_notifications/conversation_notifications_mailer/assigned_conversation_new_message.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">New Message in Assigned Conversation</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      The customer <strong>{{ conversation.contact_name }}</strong> just replied to a conversation that is assigned to you.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      <strong>Message:</strong> {{ message.text_content }}
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Reply Now</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Tin Nhắn Mới - Hội Thoại Của Bạn</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Khách hàng <strong>{{ conversation.contact_name }}</strong> vừa phản hồi lại trong cuộc trò chuyện mà bạn đang phụ trách.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      <strong>Tin nhắn:</strong> {{ message.text_content }}
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Trả Lời Ngay</a>
        </td>
      </tr>
    </table>
  LIQUID

  "app/views/mailers/agent_notifications/conversation_notifications_mailer/conversation_creation.liquid" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">New Conversation Created</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      A new conversation was created in the inbox you are participating in.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      <strong>Customer:</strong> {{ conversation.contact_name }}
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Go to Conversation</a>
        </td>
      </tr>
    </table>
    #{DIVIDER}
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Cuộc Trò Chuyện Mới</h2>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ user.available_name }}</strong>,
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Một cuộc trò chuyện mới đã được mở trong hộp thư mà bạn được thêm vào.
    </p>
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      <strong>Khách hàng:</strong> {{ conversation.contact_name }}
    </p>
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 24px;">
      <tr>
        <td align="left">
          <a href="{{ action_url }}" style="display: inline-block; background-color: #3B82F6; color: #FFFFFF; font-size: 15px; font-weight: 700; text-decoration: none; padding: 14px 32px; border-radius: 12px;">Đến Cuộc Trò Chuyện</a>
        </td>
      </tr>
    </table>
  LIQUID
}

puts "Updating \#{TEMPLATE_MAPPINGS.size} Team & Agent Notification templates..."
TEMPLATE_MAPPINGS.each do |file_path, content|
  File.write(file_path, content)
  puts "✅ Updated \#{file_path}"
end
