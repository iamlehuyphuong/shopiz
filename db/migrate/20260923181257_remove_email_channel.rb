class RemoveEmailChannel < ActiveRecord::Migration[7.1]
  def up
    purge_email_inbox_data
    normalize_removed_content_types
    remove_dead_email_templates

    remove_column :inboxes, :enable_email_collect
    remove_column :channel_web_widgets, :continuity_via_email
    drop_table :channel_email
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # Raw SQL on purpose: Channel::Email no longer exists, so any model callback
  # touching the polymorphic association would blow up with a NameError.
  def purge_email_inbox_data
    inbox_ids = 'SELECT id FROM inboxes WHERE channel_type = \'Channel::Email\''
    conversation_ids = "SELECT id FROM conversations WHERE inbox_id IN (#{inbox_ids})"

    execute "DELETE FROM reporting_events WHERE conversation_id IN (#{conversation_ids})"
    execute "DELETE FROM notifications WHERE primary_actor_type = 'Conversation' AND primary_actor_id IN (#{conversation_ids})"
    execute "DELETE FROM messages WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM conversations WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM contact_inboxes WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM inbox_members WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM inboxes WHERE channel_type = 'Channel::Email'"
  end

  # input_email (3) and incoming_email (8) are gone from the enum, so legacy rows
  # would deserialize to nil. Collapse them to text (0).
  def normalize_removed_content_types
    execute 'UPDATE messages SET content_type = 0 WHERE content_type IN (3, 8)'
  end

  def remove_dead_email_templates
    return unless table_exists?(:email_templates)

    execute "DELETE FROM email_templates WHERE name LIKE 'mailers/conversation_reply_mailer/%'"
  end
end
