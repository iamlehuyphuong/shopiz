vi_file = 'config/locales/vi.yml'
en_file = 'config/locales/en.yml'

vi_content = File.read(vi_file)
en_content = File.read(en_file)

vi_insert = %Q(
      only_one_private_reply: '%{error_code} - %{error_message}\n(Lỗi): Phản hồi riêng tư đã được gửi trước đó (trên Flowify hoặc Meta Suite). Facebook chỉ cho phép gửi 1 lần duy nhất cho mỗi bình luận.'
      private_reply_timeout: '%{error_code} - %{error_message}\n(Lỗi): Không thể gửi. Phản hồi riêng tư chỉ được phép gửi cho các bình luận được tạo trong vòng 7 ngày qua.'
)

en_insert = %Q(
      only_one_private_reply: '%{error_code} - %{error_message}\n(Error): A private reply was already sent (via Flowify or Meta Suite). Facebook only allows 1 private reply per comment.'
      private_reply_timeout: '%{error_code} - %{error_message}\n(Error): Cannot send. Private replies are only allowed for comments made within the last 7 days.'
)

vi_content.sub!(/human_agent_error: '.*?'/, "\\0#{vi_insert.chomp}")
en_content.sub!(/human_agent_error: '.*?'/, "\\0#{en_insert.chomp}")

File.write(vi_file, vi_content)
File.write(en_file, en_content)
puts "Updated locales"
