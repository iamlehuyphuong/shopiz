class RemapFeatureFlagsAfterFeatureRemoval < ActiveRecord::Migration[7.1]
  # Feature bits are positional (see Featurable). Removing entries from config/features.yml
  # shifted every later flag, so we move each account's enabled flags from the old positions
  # to the new ones. Both lists are frozen snapshots on purpose.
  OLD_FEATURES = %w[
    inbound_emails channel_email channel_facebook channel_twitter ip_lookup disable_branding
    email_continuity_on_api_channel help_center agent_bots macros agent_management team_management
    inbox_management labels custom_attributes automations canned_responses integrations voice_recorder
    report_rollup channel_website campaigns reports crm auto_resolve_conversations custom_reply_email
    custom_reply_domain audit_logs response_bot message_reply_to insert_article_in_reply inbox_view sla
    help_center_embedding_search linear_integration captain_integration custom_roles chatwoot_v4 report_v4
    contact_chatwoot_support_team shopify_integration search_with_gin channel_instagram crm_integration
    channel_voice notion_integration captain_integration_v2 whatsapp_embedded_signup whatsapp_campaign
    crm_v2 assignment_v2 twilio_content_templates advanced_search saml template_builder
    advanced_search_indexing reply_mailer_migration quoted_email_reply companies channel_zalo
    channel_zalopersonal channel_telegram channel_api deprecated_feature_64 channel_line channel_whatsapp
    channel_tiktok_shop channel_tiktok csat_review_notes captain_tasks conversation_required_attributes
    advanced_assignment sales
  ].freeze

  NEW_FEATURES = %w[
    channel_facebook ip_lookup disable_branding agent_bots macros agent_management team_management
    inbox_management labels custom_attributes automations canned_responses integrations voice_recorder
    report_rollup channel_website campaigns reports crm auto_resolve_conversations audit_logs response_bot
    message_reply_to inbox_view sla linear_integration captain_integration custom_roles report_v4
    shopify_integration search_with_gin channel_instagram crm_integration notion_integration
    whatsapp_embedded_signup whatsapp_campaign advanced_search template_builder
    advanced_search_indexing companies channel_zalo channel_zalopersonal channel_telegram channel_api
    channel_whatsapp channel_tiktok_shop channel_tiktok csat_review_notes captain_tasks
    conversation_required_attributes advanced_assignment sales
  ].freeze

  # Featurable keeps 63 bits per column: positions 1..63 in feature_flags, 64.. in feature_flags_2.
  BITS_PER_COLUMN = 63

  def up
    select_rows('SELECT id, feature_flags, feature_flags_2 FROM accounts').each do |id, flags, flags2|
      execute("UPDATE accounts SET feature_flags = #{remap(flags.to_i, flags2.to_i)}, feature_flags_2 = 0 WHERE id = #{id.to_i}")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def remap(flags, flags2)
    NEW_FEATURES.each_with_index.sum do |name, new_index|
      if name == 'advanced_assignment'
        old_index_1 = OLD_FEATURES.index('assignment_v2')
        old_index_2 = OLD_FEATURES.index('advanced_assignment')
        source1, bit1 = old_index_1 < BITS_PER_COLUMN ? [flags, old_index_1] : [flags2, old_index_1 - BITS_PER_COLUMN]
        source2, bit2 = old_index_2 < BITS_PER_COLUMN ? [flags, old_index_2] : [flags2, old_index_2 - BITS_PER_COLUMN]
        is_enabled = (source1[bit1] == 1) || (source2[bit2] == 1)
        is_enabled ? (1 << new_index) : 0
      else
        old_index = OLD_FEATURES.index(name)
        source, bit = old_index < BITS_PER_COLUMN ? [flags, old_index] : [flags2, old_index - BITS_PER_COLUMN]
        source[bit] == 1 ? (1 << new_index) : 0
      end
    end
  end
end
