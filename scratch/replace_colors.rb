# encoding: utf-8
require 'fileutils'
require 'set'

# Directories to process
SEARCH_DIRS = [
  'app/javascript',
  'enterprise/app',
  'app/views'
].select { |d| Dir.exist?(d) }

# File extensions to include
ALLOWED_EXTENSIONS = ['.vue', '.js', '.scss', '.erb', '.json']

# Patterns to ignore
IGNORED_PATHS = [
  '/node_modules/',
  '/public/',
  '/build/',
  '/dist/',
  '/vendor/',
  '.svg',
  '.png',
  '.jpg',
  '.jpeg',
  '.gif'
]

REPLACEMENTS = {
  /(?<!\w)n-brand(?!\w)/ => 'n-orange',
  /(?<!\w)n-blue(?!\w)/ => 'n-orange',
  /(?<!\w)n-blue-text(?!\w)/ => 'n-orange-text',
  /(?<!\w)text-blue(?!\w)/ => 'text-orange',
  /(?<!\w)border-blue(?!\w)/ => 'border-orange',
  /(?<!\w)solid-blue(?!\w)/ => 'solid-orange'
}

changed_files_count = 0

SEARCH_DIRS.each do |dir|
  Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).each do |file_path|
    next unless File.file?(file_path)
    
    ext = File.extname(file_path)
    next unless ALLOWED_EXTENSIONS.include?(ext)
    
    next if IGNORED_PATHS.any? { |ignored| file_path.include?(ignored) }
    next if file_path.end_with?('icons.js')
    
    content = File.read(file_path, encoding: 'UTF-8')
    new_content = content.dup
    
    REPLACEMENTS.each do |pattern, replacement|
      new_content.gsub!(pattern, replacement)
    end
    
    if content != new_content
      File.write(file_path, new_content, encoding: 'UTF-8')
      changed_files_count += 1
      puts "Updated: #{file_path}"
    end
  end
end

puts "\nTotal files updated: #{changed_files_count}"
