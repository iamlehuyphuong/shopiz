# frozen_string_literal: true

namespace :email_templates do
  desc 'Seed default email templates from app/views'
  task seed_defaults: :environment do
    puts 'Seeding default email templates...'

    base_paths = [
      Rails.root.join('app/views/mailers'),
      Rails.root.join('app/views/devise/mailer'),
      Rails.root.join('app/views/layouts/mailer')
    ]

    base_paths.each do |base_path|
      Dir.glob(base_path.join('**', '*.{html.erb,liquid}')).each do |file_path|
        # Extract the relative path without layout/format extensions
        # e.g. "app/views/mailers/conversation_reply_mailer/email_reply.html.erb"
        # -> "mailers/conversation_reply_mailer/email_reply"

        # Determine prefix (mailers/ or devise/mailer/) depending on where the file is
        # Actually ActionView resolver names the view path relative to standard views folder
        # For mailers it looks up things like "conversation_reply_mailer/email_reply"
        # For devise it looks up "devise/mailer/confirmation_instructions"

        relative_to_views = Pathname.new(file_path).relative_path_from(Rails.root.join('app/views')).to_s

        # Remove extensions (.html.erb or .liquid)
        name = relative_to_views.sub(/\.html\.erb\z/, '').sub(/\.liquid\z/, '')

        body = File.read(file_path)

        t_type = relative_to_views.to_s.start_with?('layouts/') ? :layout : :content

        template = EmailTemplate.find_or_initialize_by(
          name: name,
          account_id: nil,
          template_type: t_type,
          locale: :en
        )

        if template.new_record?
          template.body = body
          template.save!
          puts "Created template: #{name}"
        else
          # Update existing template if it was seeded from these defaults and hasn't been changed?
          # To avoid overwriting admin customizations, we only initialize.
          puts "Skipped (already exists): #{name}"
        end
      end
    end

    puts 'Completed seeding email templates!'
  end
end
