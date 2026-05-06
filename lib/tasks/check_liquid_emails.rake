namespace :email_templates do
  task check_html_full: :environment do
    require 'nokogiri'
    layout = EmailTemplate.find_by(name: 'layouts/mailer/base')
    templates = EmailTemplate.where.not(name: 'layouts/mailer/base')

    mock_data = {
      'user' => { 'name' => 'Alice', 'email' => 'alice@example.com' },
      'account' => { 'name' => 'Acme Corp' },
      'conversation' => { 'id' => 123 },
      'message' => { 'content' => 'Hello there', 'sender_name' => 'Bob' },
      'action_url' => 'https://example.com'
    }

    templates.each do |template|
      begin
        liquid_template = Liquid::Template.parse(template.body)
        content = liquid_template.render(mock_data, strict_variables: false)

        liquid_layout = Liquid::Template.parse(layout.body)
        final_html = liquid_layout.render('content_for_layout' => content, strict_variables: false)

        doc = Nokogiri::HTML::Document.parse(final_html)
        errors = doc.errors.reject { |e| e.message.include?('htmlParseEntityRef: expecting') } # ignore url parameter errors occasionally
        if errors.any?
          puts "==========================================================="
          puts "Template: #{template.name}"
          puts "ERRORS FOUND:"
          puts errors.map(&:message).join("\n")
        end
      rescue => e
        puts "EXCEPTION in #{template.name}: #{e.message}"
      end
    end
  end
end
