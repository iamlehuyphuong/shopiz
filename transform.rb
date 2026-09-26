# encoding: UTF-8
content = File.read('app/views/home/index.html.erb', encoding: 'UTF-8')

# Global background and borders
content.gsub!('bg-dark-bg/80', 'bg-white/80')
content.gsub!('bg-dark-bg', 'bg-slate-50')
content.gsub!('bg-dark-card', 'bg-white')
content.gsub!('border-dark-border', 'border-slate-200')
content.gsub!('bg-[#0f172a]', 'bg-white')

# Specific text replacements
content.gsub!('text-white', 'text-slate-900')

# Revert text-slate-900 back to text-white for buttons and specific areas
content.gsub!('bg-primary-600 hover:bg-primary-700 text-slate-900', 'bg-primary-600 hover:bg-primary-700 text-white')
content.gsub!('bg-slate-700 flex items-center justify-center text-sm font-medium text-slate-900', 'bg-slate-700 flex items-center justify-center text-sm font-medium text-white')
content.gsub!('bg-primary-500 text-slate-900 text-xs font-bold', 'bg-primary-500 text-white text-xs font-bold')
content.gsub!('text-slate-900 mb-3">Sẵn sàng bứt phá doanh thu?', 'text-white mb-3">Sẵn sàng bứt phá doanh thu?')
content.gsub!('<svg class="w-5 h-5 text-slate-900"', '<svg class="w-5 h-5 text-white"') # footer logo
content.gsub!('bg-primary-600 text-slate-900 hover:bg-primary-700', 'bg-primary-600 text-white hover:bg-primary-700')

# Slate text colors
content.gsub!('text-slate-300', 'text-slate-600')
content.gsub!('text-slate-400', 'text-slate-500')
content.gsub!('hover:text-slate-900', 'hover:text-primary-600') # footer links
content.gsub!('hover:text-white', 'hover:text-primary-600')

# Specific components
content.gsub!('bg-slate-800/50 border border-slate-700', 'bg-slate-100 border border-slate-200') # Hero pill
content.gsub!('bg-white hover:bg-slate-800 border border-slate-200 text-slate-900', 'bg-white hover:bg-slate-50 border border-slate-200 text-slate-700') # Demo button

# Pricing secondary buttons
content.gsub!('border border-slate-700 text-slate-900 hover:bg-slate-800', 'border border-slate-300 text-slate-700 hover:bg-slate-50')

# Section backgrounds
content.gsub!('bg-white/30 border-y border-slate-200', 'bg-slate-50 border-y border-slate-200') # section 5 was bg-dark-card/30 -> bg-white/30. We want bg-slate-50.
content.gsub!('bg-white/50', 'bg-slate-50') # section 7 was bg-dark-card/50 -> bg-white/50.

File.write('app/views/home/index.html.erb', content)
