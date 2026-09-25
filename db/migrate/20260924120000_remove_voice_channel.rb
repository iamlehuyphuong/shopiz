class RemoveVoiceChannel < ActiveRecord::Migration[7.1]
  def up
    purge_voice_inbox_data
    drop_table :channel_voice
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # Raw SQL on purpose: Channel::Voice no longer exists, so any model callback
  # touching the polymorphic association would blow up with a NameError.
  def purge_voice_inbox_data
    inbox_ids = "SELECT id FROM inboxes WHERE channel_type = 'Channel::Voice'"
    conversation_ids = "SELECT id FROM conversations WHERE inbox_id IN (#{inbox_ids})"

    # Tables holding a foreign key to conversations must go first, or the
    # conversation delete aborts on a constraint violation.
    execute "DELETE FROM bookings WHERE conversation_id IN (#{conversation_ids})"
    execute "DELETE FROM zalo_group_members WHERE conversation_id IN (#{conversation_ids})"

    execute "DELETE FROM campaigns WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM reporting_events WHERE conversation_id IN (#{conversation_ids})"
    execute "DELETE FROM notifications WHERE primary_actor_type = 'Conversation' AND primary_actor_id IN (#{conversation_ids})"
    execute "DELETE FROM messages WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM conversations WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM contact_inboxes WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM inbox_members WHERE inbox_id IN (#{inbox_ids})"
    execute "DELETE FROM inboxes WHERE channel_type = 'Channel::Voice'"
  end
end
