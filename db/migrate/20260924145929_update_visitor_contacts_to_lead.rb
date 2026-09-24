class UpdateVisitorContactsToLead < ActiveRecord::Migration[7.1]
  def up
    execute(<<~SQL)
      UPDATE contacts
      SET contact_type = 1
      WHERE contact_type = 0
        AND (
          COALESCE(email, '') <> ''
          OR COALESCE(phone_number, '') <> ''
          OR COALESCE(identifier, '') <> ''
        )
    SQL
  end

  def down
    # Not easily reversible without losing genuine visitor status
  end
end
