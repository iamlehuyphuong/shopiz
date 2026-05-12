require 'yaml'

file_path = 'config/agents/tools.yml'
tools = YAML.load_file(file_path)

ecom_prefixes = %w[kiotviet sapo haravan shopify woocommerce nhanhvn tiktok_shop]

tools.each do |tool|
  if ecom_prefixes.any? { |prefix| tool['id'].start_with?("#{prefix}_") }
    tool['hidden'] = true
  end
end

File.write(file_path, tools.to_yaml)
puts "Updated tools.yml"
