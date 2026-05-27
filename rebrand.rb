require 'fileutils'

def process_file(file)
  return unless File.file?(file)
  
  begin
    content = File.read(file, encoding: 'UTF-8')
    original_content = content.dup
    
    # Check if file has any match before replacing
    return unless content.match?(/shopiz/i)
    
    # 1. Replace domain
    content.gsub!('flowify.vn', 'flowify.vn')
    
    # 2. Replace exact Flowify -> Flowify
    content.gsub!('Flowify', 'Flowify')
    
    # 3. Replace exact SHOPIZ -> FLOWIFY
    content.gsub!('SHOPIZ', 'FLOWIFY')
    
    # 4. Protect specific strings just in case
    content.gsub!('shopiz_development', '__SHOPIZ_DEV__')
    content.gsub!('shopiz_test', '__SHOPIZ_TEST__')
    content.gsub!('shopiz_production', '__SHOPIZ_PROD__')
    content.gsub!('shopiz/shopiz', '__SHOPIZ_REPO__')
    
    content.gsub!('shopiz', 'flowify')
    
    # Restore protected strings
    content.gsub!('__SHOPIZ_DEV__', 'shopiz_development')
    content.gsub!('__SHOPIZ_TEST__', 'shopiz_test')
    content.gsub!('__SHOPIZ_PROD__', 'shopiz_production')
    content.gsub!('__SHOPIZ_REPO__', 'shopiz/shopiz')
    
    if content != original_content
      File.write(file, content)
      return true
    end
  rescue => e
    puts "Error processing #{file}: #{e.message}"
  end
  false
end

changed_files_count = 0

# Only target frontend-related directories
target_dirs = ['app/javascript', 'app/views', 'public']

target_dirs.each do |dir|
  Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).each do |file|
    next if file.end_with?('.') || file.end_with?('..')
    next if File.directory?(file)
    
    # Skip images or binaries to be safe
    next if file.match?(/\.(png|jpg|jpeg|gif|ico|pdf|zip|tar|gz|mp3|mov|mp4|ogg|DS_Store)$/i)
    
    if process_file(file)
      changed_files_count += 1
    end
  end
end

puts "Replaced strings in #{changed_files_count} files."
