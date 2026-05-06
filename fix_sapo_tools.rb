files = [
  'enterprise/lib/captain/tools/sapo_get_order_tool.rb',
  'enterprise/lib/captain/tools/sapo_get_product_tool.rb'
]

files.each do |file|
  content = File.read(file)
  
  # Replace base class
  content = content.gsub(/< Base/, '< Captain::Tools::BasePublicTool')
  
  # Extract name
  tool_desc = content.match(/def description\s*(?:'|")(.*?)(?:'|")\s*end/m)
  
  # Handle parameters
  params_block = content.match(/def parameters\s*\[(.*?)\]\s*end/m)
  params_declarations = ""
  if params_block
    params_str = params_block[1]
    params_str.scan(/\{\s*name:\s*['"](.*?)['"],\s*type:\s*['"](.*?)['"],\s*description:\s*['"](.*?)['"](?:,\s*required:\s*(true|false))?\s*\}/) do |m|
      name, type, desc, req = m
      req_str = req == 'false' ? ", required: false" : ""
      params_declarations += "  param :#{name}, type: '#{type}', desc: '#{desc}'#{req_str}\n"
    end
  end

  # Remove old methods
  content = content.gsub(/  def name.*?end\n*/m, '')
  content = content.gsub(/  def description.*?end\n*/m, '')
  content = content.gsub(/  def parameters.*?end\n*/m, '')

  if tool_desc
    new_definitions = <<~RUBY
      description '#{tool_desc[1]}'
    #{params_declarations}
    RUBY
    content = content.sub(/(\s*def (execute))/, "\n  " + new_definitions.strip + "\n" + '\1')
  end
  
  # Adjust execute to perform
  content = content.sub(/def execute\(arguments\)/, "def perform(tool_context, **args)\n    arguments = args.stringify_keys")

  File.write(file, content)
end
