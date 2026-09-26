class ContactMergeAction
  include Events::Types
  pattr_initialize [:account!, :base_contact!, :mergee_contact!]

  def perform
    # This case happens when an agent updates a contact email in dashboard,
    # while the contact also update his email via email collect box
    return @base_contact if base_contact.id == mergee_contact.id

    @base_is_livechat = from_livechat?(@base_contact)
    @mergee_is_livechat = from_livechat?(@mergee_contact)

    ActiveRecord::Base.transaction do
      validate_contacts
      merge_conversations
      merge_messages
      merge_contact_inboxes
      merge_contact_notes
      merge_csat_survey_responses
      merge_bookings
      merge_conversation_orders
      merge_contact_optins
      merge_and_remove_mergee_contact
    end
    @base_contact
  end

  private

  def from_livechat?(contact)
    ContactInbox.joins(:inbox).exists?(contact_id: contact.id, inboxes: { channel_type: 'Channel::WebWidget' })
  end

  def validate_contacts
    return if belongs_to_account?(@base_contact) && belongs_to_account?(@mergee_contact)

    raise StandardError, 'contact does not belong to the account'
  end

  def belongs_to_account?(contact)
    @account.id == contact.account_id
  end

  def merge_conversations
    Conversation.where(contact_id: @mergee_contact.id).update_all(contact_id: @base_contact.id)
  end

  def merge_contact_notes
    Note.where(contact_id: @mergee_contact.id, account_id: @mergee_contact.account_id).update_all(contact_id: @base_contact.id)
  end

  def merge_messages
    Message.where(sender: @mergee_contact).update_all(sender_id: @base_contact.id)
  end

  def merge_contact_inboxes
    ContactInbox.where(contact_id: @mergee_contact.id).update_all(contact_id: @base_contact.id)
  end

  def merge_csat_survey_responses
    CsatSurveyResponse.where(contact_id: @mergee_contact.id).update_all(contact_id: @base_contact.id)
  end

  def merge_bookings
    Booking.where(contact_id: @mergee_contact.id).update_all(contact_id: @base_contact.id)
  end

  def merge_conversation_orders
    ConversationOrder.where(contact_id: @mergee_contact.id).update_all(contact_id: @base_contact.id)
  end

  def merge_contact_optins
    ContactOptin.where(contact_id: @mergee_contact.id).update_all(contact_id: @base_contact.id)
  end

  def merge_and_remove_mergee_contact
    mergable_attribute_keys = %w[identifier name email phone_number additional_attributes custom_attributes]
    base_contact_attributes = base_contact.attributes.slice(*mergable_attribute_keys).compact_blank
    mergee_contact_attributes = mergee_contact.attributes.slice(*mergable_attribute_keys).compact_blank

    # attributes in base contact are given preference
    merged_attributes = mergee_contact_attributes.deep_merge(base_contact_attributes)

    # specially merge sources to retain all channels
    if mergee_contact_attributes.dig('additional_attributes', 'sources').is_a?(Array) &&
       base_contact_attributes.dig('additional_attributes', 'sources').is_a?(Array)
      merged_sources = mergee_contact_attributes['additional_attributes']['sources'] | base_contact_attributes['additional_attributes']['sources']
      merged_attributes['additional_attributes']['sources'] = merged_sources.uniq.compact_blank
    elsif mergee_contact_attributes.dig('additional_attributes', 'sources').is_a?(Array)
      merged_attributes['additional_attributes']['sources'] = mergee_contact_attributes['additional_attributes']['sources'].uniq.compact_blank
    end

    if @base_is_livechat && !@mergee_is_livechat
      merged_attributes['name'] = mergee_contact_attributes['name'] if mergee_contact_attributes['name'].present?
      merged_attributes['email'] = mergee_contact_attributes['email'] if mergee_contact_attributes['email'].present?
    elsif !@base_is_livechat && @mergee_is_livechat
      merged_attributes['name'] = base_contact_attributes['name'] if base_contact_attributes['name'].present?
      merged_attributes['email'] = base_contact_attributes['email'] if base_contact_attributes['email'].present?
    end

    @mergee_contact.reload.destroy!
    Rails.configuration.dispatcher.dispatch(CONTACT_MERGED, Time.zone.now, contact: @base_contact,
                                                                           tokens: [@base_contact.contact_inboxes.filter_map(&:pubsub_token)],
                                                                           mergee_contact_id: @mergee_contact.id)
    @base_contact.skip_auto_merge = true
    @base_contact.update!(merged_attributes)
  end
end
