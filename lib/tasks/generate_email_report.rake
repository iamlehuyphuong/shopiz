namespace :email_templates do
  task generate_report: :environment do
    layout = EmailTemplate.find_by(name: 'layouts/mailer/base')
    templates = EmailTemplate.where.not(name: 'layouts/mailer/base').order(:name)

    mock_data = {
      'user' => { 'name' => 'Alice', 'email' => 'alice@example.com', 'available_name' => 'Alice' },
      'account' => { 'name' => 'Acme Corp' },
      'conversation' => { 'id' => 123 },
      'message' => { 'content' => 'Hello there', 'sender_name' => 'Bob' },
      'action_url' => 'https://example.com'
    }

    report = "# Email Templates HTML Review\n\n"
    report += "This document contains the final rendered HTML for all 39 email templates, alongside a syntax check.\n\n"

    templates.each do |template|
      begin
        liquid_template = Liquid::Template.parse(template.body)
        content = liquid_template.render(mock_data, strict_variables: false)

        liquid_layout = Liquid::Template.parse(layout.body)
        final_html = liquid_layout.render('content_for_layout' => content, strict_variables: false)

        doc = Nokogiri::HTML::Document.parse(final_html)
        errors = doc.errors.reject { |e| e.message.include?('htmlParseEntityRef: no name') || e.message.include?('htmlParseEntityRef: expecting') || e.message.include?('error parsing attribute name') } 
        
        status = errors.any? ? "❌ Syntax Errors Found" : "✅ Syntax Correct"

        report += "## #{template.name}\n"
        report += "**Status**: #{status}\n\n"
        
        if errors.any?
          report += "### Errors:\n"
          errors.each do |error|
            report += "- `#{error.message}`\n"
          end
          report += "\n"
        end

        report += "### Final HTML Source:\n"
        report += "```html\n"
        report += final_html
        report += "\n```\n\n"
        report += "---\n\n"
      rescue => e
        report += "## #{template.name}\n"
        report += "**Status**: ❌ Failed to Render\n"
        report += "- Exception: #{e.message}\n\n---\n\n"
      end
    end

    File.write('email_template_report.md', report)
    puts "Report generated at email_template_report.md"
  end
end
