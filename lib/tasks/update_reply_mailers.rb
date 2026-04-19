require 'fileutils'

DIVIDER = "<hr style=\"border: 0; border-bottom: 1px solid #E2E8F0; margin: 24px 0;\" />"

TEMPLATE_MAPPINGS = {
  "app/views/mailers/conversation_reply_mailer/email_reply.html.erb" => <<~LIQUID,
    {% if message.html_content != blank %}
      {{ message.html_content }}
    {% elsif message.content != blank %}
      {{ message.content | newline_to_br }}
    {% endif %}

    {% if message.attachments != blank %}
      <div style="margin-top: 12px; border-top: 1px solid #CBD5E1; padding-top: 12px; color: #475569;">
        <strong>Attachments / Tiệp đính kèm:</strong><br/>
        {% for attachment in message.attachments %}
          <a href="{{ attachment.file_url }}" target="_blank" style="color: #3B82F6;">{{ attachment.filename }}</a><br/>
        {% endfor %}
      </div>
    {% endif %}
  LIQUID

  "app/views/mailers/conversation_reply_mailer/reply_without_summary.html.erb" => <<~LIQUID,
    {% if message.html_content != blank %}
      {{ message.html_content }}
    {% elsif message.content != blank %}
      {{ message.content | newline_to_br }}
    {% endif %}

    {% if message.attachments != blank %}
      <div style="margin-top: 12px; border-top: 1px solid #CBD5E1; padding-top: 12px; color: #475569;">
        <strong>Attachments / Tiệp đính kèm:</strong><br/>
        {% for attachment in message.attachments %}
          <a href="{{ attachment.file_url }}" target="_blank" style="color: #3B82F6;">{{ attachment.filename }}</a><br/>
        {% endfor %}
      </div>
    {% endif %}
  LIQUID
}

puts "Updating \#{TEMPLATE_MAPPINGS.size} Conversation Reply templates..."
TEMPLATE_MAPPINGS.each do |file_path, content|
  File.write(file_path, content)
  puts "✅ Updated \#{file_path}"
end
