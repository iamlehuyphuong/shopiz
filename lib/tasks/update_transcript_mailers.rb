require 'fileutils'

DIVIDER = "<hr style=\"border: 0; border-bottom: 1px solid #E2E8F0; margin: 24px 0;\" />"

TEMPLATE_MAPPINGS = {
  "app/views/mailers/conversation_reply_mailer/reply_with_summary.html.erb" => <<~LIQUID,
    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Hi <strong>{{ conversation.contact_name }}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Here is the summary of the latest messages during your support session:
    </p>

    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom: 20px;">
      {% for msg in messages %}
        <tr>
          <td style="padding-bottom: 8px;">
            <b style="color: #1E293B; font-size: 14px;">
              {% if msg.incoming? %}
                You
              {% else %}
                {% if msg.sender_display_name != blank %}{{ msg.sender_display_name }}{% else %}Support Agent{% endif %}
              {% endif %}
            </b>
          </td>
        </tr>
        <tr>
          <td style="padding: 12px 16px; margin-bottom: 16px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; font-size: 14px; color: #334155;">
            {% if msg.html_content != blank %}
              {{ msg.html_content }}
            {% elsif msg.content != blank %}
              {{ msg.content | newline_to_br }}
            {% endif %}

            {% if msg.attachments != blank %}
              <div style="margin-top: 12px; border-top: 1px solid #CBD5E1; padding-top: 12px;">
                <strong>Attachments:</strong><br/>
                {% for attachment in msg.attachments %}
                  <a href="{{ attachment.file_url }}" target="_blank" style="color: #3B82F6;">{{ attachment.filename }}</a><br/>
                {% endfor %}
              </div>
            {% endif %}
          </td>
        </tr>
        <tr><td style="height: 12px;"></td></tr>
      {% endfor %}
    </table>

    #{DIVIDER}

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 20px;">
      Xin chào <strong>{{ conversation.contact_name }}</strong>,
    </p>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Dưới đây là tóm tắt các tin nhắn mới nhất trong quá trình hỗ trợ của bạn:
    </p>

    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom: 20px;">
      {% for msg in messages %}
        <tr>
          <td style="padding-bottom: 8px;">
            <b style="color: #1E293B; font-size: 14px;">
              {% if msg.incoming? %}
                Bạn
              {% else %}
                {% if msg.sender_display_name != blank %}{{ msg.sender_display_name }}{% else %}Bot Hỗ Trợ{% endif %}
              {% endif %}
            </b>
          </td>
        </tr>
        <tr>
          <td style="padding: 12px 16px; margin-bottom: 16px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; font-size: 14px; color: #334155;">
            {% if msg.html_content != blank %}
              {{ msg.html_content }}
            {% elsif msg.content != blank %}
              {{ msg.content | newline_to_br }}
            {% endif %}

            {% if msg.attachments != blank %}
              <div style="margin-top: 12px; border-top: 1px solid #CBD5E1; padding-top: 12px;">
                <strong>Đính kèm:</strong><br/>
                {% for attachment in msg.attachments %}
                  <a href="{{ attachment.file_url }}" target="_blank" style="color: #3B82F6;">{{ attachment.filename }}</a><br/>
                {% endfor %}
              </div>
            {% endif %}
          </td>
        </tr>
        <tr><td style="height: 12px;"></td></tr>
      {% endfor %}
    </table>
  LIQUID

  "app/views/mailers/conversation_reply_mailer/conversation_transcript.html.erb" => <<~LIQUID,
    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Conversation Transcript</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Below is the complete transcript of your recent support conversation (ID: \\\#{{ conversation.display_id }}):
    </p>

    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom: 20px;">
      {% for msg in messages %}
        <tr>
          <td style="padding-bottom: 8px;">
            <b style="color: #1E293B; font-size: 14px;">
              {% if msg.incoming? %}
                You
              {% else %}
                {% if msg.sender_display_name != blank %}{{ msg.sender_display_name }}{% else %}Support Agent{% endif %}
              {% endif %}
            </b>
          </td>
        </tr>
        <tr>
          <td style="padding: 12px 16px; margin-bottom: 16px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; font-size: 14px; color: #334155;">
            {% if msg.html_content != blank %}
              {{ msg.html_content }}
            {% elsif msg.content != blank %}
              {{ msg.content | newline_to_br }}
            {% endif %}

            {% if msg.attachments != blank %}
              <div style="margin-top: 12px; border-top: 1px solid #CBD5E1; padding-top: 12px;">
                <strong>Attachments:</strong><br/>
                {% for attachment in msg.attachments %}
                  <a href="{{ attachment.file_url }}" target="_blank" style="color: #3B82F6;">{{ attachment.filename }}</a><br/>
                {% endfor %}
              </div>
            {% endif %}
          </td>
        </tr>
        <tr><td style="height: 12px;"></td></tr>
      {% endfor %}
    </table>

    #{DIVIDER}

    <h2 style="color: #1E293B; font-size: 20px; font-weight: 700; margin-top: 0; margin-bottom: 16px;">Bản Ghi Cuộc Trò Chuyện</h2>

    <p style="color: #475569; font-size: 16px; line-height: 1.6; margin-top: 0; margin-bottom: 24px;">
      Dưới đây là toàn bộ nội dung cuộc trò chuyện hỗ trợ (Mã: \\\#{{ conversation.display_id }}) của bạn:
    </p>

    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom: 20px;">
      {% for msg in messages %}
        <tr>
          <td style="padding-bottom: 8px;">
            <b style="color: #1E293B; font-size: 14px;">
              {% if msg.incoming? %}
                Bạn
              {% else %}
                {% if msg.sender_display_name != blank %}{{ msg.sender_display_name }}{% else %}Bot Hỗ Trợ{% endif %}
              {% endif %}
            </b>
          </td>
        </tr>
        <tr>
          <td style="padding: 12px 16px; margin-bottom: 16px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; font-size: 14px; color: #334155;">
            {% if msg.html_content != blank %}
              {{ msg.html_content }}
            {% elsif msg.content != blank %}
              {{ msg.content | newline_to_br }}
            {% endif %}

            {% if msg.attachments != blank %}
              <div style="margin-top: 12px; border-top: 1px solid #CBD5E1; padding-top: 12px;">
                <strong>Đính kèm:</strong><br/>
                {% for attachment in msg.attachments %}
                  <a href="{{ attachment.file_url }}" target="_blank" style="color: #3B82F6;">{{ attachment.filename }}</a><br/>
                {% endfor %}
              </div>
            {% endif %}
          </td>
        </tr>
        <tr><td style="height: 12px;"></td></tr>
      {% endfor %}
    </table>
  LIQUID
}

puts "Updating \#{TEMPLATE_MAPPINGS.size} Transcript Reply templates..."
TEMPLATE_MAPPINGS.each do |file_path, content|
  File.write(file_path, content)
  puts "✅ Updated \#{file_path}"
end
