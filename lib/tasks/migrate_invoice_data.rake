namespace :data_migrations do
  desc 'Migrate invoice info from users to accounts'
  task migrate_invoice_info: :environment do
    puts 'Starting data migration...'

    # We use raw SQL because the columns might have been dropped from the schema in User model
    # This safely copies data from users table to accounts table by joining on account_users
    sql = <<-SQL
      UPDATE accounts a
      SET#{' '}
        type_id = u.type_id,
        address = u.address,
        company_name = u.company_name,
        company_address = u.company_address,
        company_email = u.company_email,
        company_tax_id = u.company_tax_id,
        id_number = u.id_number
      FROM users u
      INNER JOIN account_users au ON au.user_id = u.id
      WHERE au.account_id = a.id
        AND (u.type_id IS NOT NULL OR u.company_name IS NOT NULL OR u.id_number IS NOT NULL);
    SQL

    begin
      result = ActiveRecord::Base.connection.execute(sql)
      puts "Successfully migrated data for #{result.cmd_tuples} accounts."
    rescue StandardError => e
      puts "Data migration skipped or failed (columns might be dropped already): #{e.message}"
    end
  end
end
