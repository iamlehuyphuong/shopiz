class PurgeRemovedChannels < ActiveRecord::Migration[7.1]
  REMOVED_CHANNEL_TYPES = %w[Channel::Line Channel::Sms Channel::TwilioSms Channel::TwitterProfile Channel::Email].freeze

  def up
    purge_removed_inbox_data
    drop_table :channel_line, if_exists: true
    drop_table :channel_sms, if_exists: true
    drop_table :channel_twilio_sms, if_exists: true
    drop_table :channel_twitter_profiles, if_exists: true
    drop_table :article_embeddings, if_exists: true
    drop_table :portals_members, if_exists: true
    drop_table :account_saml_settings, if_exists: true

    # content_type 7 was `article`, which no longer exists in the Message enum
    execute 'UPDATE messages SET content_type = 0 WHERE content_type = 7'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # Raw SQL on purpose: the channel models no longer exist, so any model callback
  # touching the polymorphic association would blow up with a NameError.
  def purge_removed_inbox_data
    types = REMOVED_CHANNEL_TYPES.map { |type| connection.quote(type) }.join(', ')
    inbox_ids = "SELECT id FROM inboxes WHERE channel_type IN (#{types})"
    conversation_ids = "SELECT id FROM conversations WHERE inbox_id IN (#{inbox_ids})"

    # Tables holding a foreign key to conversations/inboxes must go first.
    execute "DELETE FROM bookings WHERE conversation_id IN (#{conversation_ids})"
    execute "DELETE FROM zalo_group_members WHERE conversation_id IN (#{conversation_ids})"
    execute "DELETE FROM contact_optins WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM inbox_label_mappings WHERE inbox_id IN (#{inbox_ids})"

    execute "DELETE FROM campaigns WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM reporting_events WHERE conversation_id IN (#{conversation_ids})"
    execute "DELETE FROM notifications WHERE primary_actor_type = 'Conversation' AND primary_actor_id IN (#{conversation_ids})"
    execute "DELETE FROM messages WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM conversations WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM contact_inboxes WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM inbox_members WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM inboxes WHERE channel_type IN (#{types})"
  end
end
