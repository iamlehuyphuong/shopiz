files = [
  'enterprise/app/services/captain/tools/copilot/haravan_search_orders_service.rb',
  'enterprise/app/services/captain/tools/copilot/haravan_search_customers_service.rb',
  'enterprise/app/services/captain/tools/copilot/haravan_search_products_service.rb',
  'enterprise/app/services/captain/tools/copilot/woocommerce_search_orders_service.rb',
  'enterprise/app/services/captain/tools/copilot/woocommerce_search_customers_service.rb',
  'enterprise/app/services/captain/tools/copilot/woocommerce_search_products_service.rb',
  'enterprise/app/services/captain/tools/copilot/sapo_search_orders_service.rb',
  'enterprise/app/services/captain/tools/copilot/sapo_search_customers_service.rb',
  'enterprise/app/services/captain/tools/copilot/sapo_search_products_service.rb'
]

files.each do |file|
  content = File.read(file)
  
  # 1. Replace base class
  content = content.gsub(/< Captain::Tools::Copilot::BaseTool/, '< Captain::Tools::BaseTool')
  content = content.gsub(/< Captain::Tools::Copilot::BaseService/, '< Captain::Tools::BaseTool')
  
  # 2. Extract name
  tool_name = content.match(/def (?:tool_)?name\s*(?:'|")(.*?)(?:'|")\s*end/m)
  
  # 3. Extract description
  tool_desc = content.match(/def (?:tool_)?description\s*(?:'|")(.*?)(?:'|")\s*end/m)
  
  # 4. Handle parameters
  params_block = content.match(/def (?:tool_)?parameters\s*\[(.*?)\]\s*end/m)
  params_declarations = ""
  if params_block
    params_str = params_block[1]
    params_str.scan(/\{\s*name:\s*['"](.*?)['"],\s*type:\s*['"](.*?)['"],\s*description:\s*['"](.*?)['"](?:,\s*required:\s*(true|false))?\s*\}/) do |m|
      name, type, desc, req = m
      req_str = req == 'false' ? ", required: false" : ""
      params_declarations += "  param :#{name}, type: :#{type}, desc: '#{desc}'#{req_str}\n"
    end
  end

  # Remove the old methods
  content = content.gsub(/  def (?:tool_)?name.*?end\n*/m, '')
  content = content.gsub(/  def (?:tool_)?description.*?end\n*/m, '')
  content = content.gsub(/  def (?:tool_)?parameters.*?end\n*/m, '')

  # 5. Insert new definitions
  if tool_name && tool_desc
    new_definitions = <<~RUBY
      def self.name
        '#{tool_name[1]}'
      end

      description '#{tool_desc[1]}'
    #{params_declarations}
    RUBY
    
    content = content.sub(/(\s*def (active\?|execute))/, "\n  " + new_definitions.strip + "\n" + '\1')
  end
  
  # 6. Adjust execute argument
   content = content.gsub(/def execute\(arguments\)/, "def execute(**args)\n    arguments = args.stringify_keys")

  File.write(file, content)
end
