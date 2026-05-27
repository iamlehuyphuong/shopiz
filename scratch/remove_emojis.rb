require 'fileutils'

emojis = ['✅', '📦', '🎯', '⬆️', '🔄', '📋', '👤', '📧', '💰', '⚠️', '❓', '🟢', '🟡', '🔴', '❌']
emoji_regex = Regexp.new(emojis.join('|'))

Dir.glob('enterprise/app/services/captain/tools/**/*.rb').each do |file|
  content = File.read(file, encoding: 'UTF-8')
  
  # Find and remove emojis. Also clean up any trailing spaces caused by removal before the emoji.
  # For example: "✅ Draft order" -> " Draft order" -> "Draft order"
  new_content = content.gsub(emoji_regex, '')
  
  # Clean up spaces left by emojis at the beginning of strings or after formatting
  # E.g. "   Draft order" -> "  Draft order"
  new_content = new_content.gsub(/\[" /) { '["' }
  new_content = new_content.gsub(/\\n /) { '\n' }
  new_content = new_content.gsub(/" /) { '"' } # " Customer:" -> "Customer:"
  
  # Note: A simple string strip inside quotes might be risky with naive gsub, 
  # so let's just do the basic emoji strip and rely on rubocop / manual check for formatting.
  
  if content != new_content
    File.write(file, new_content)
    puts "Updated #{file}"
  end
end
