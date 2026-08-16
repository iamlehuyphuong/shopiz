module Labelable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :labels
  end

  def update_labels(labels = nil)
    old_labels = label_list.dup
    update!(label_list: labels)
    dispatch_label_update_event(old_labels, label_list)
  end

  def add_labels(new_labels = nil)
    return if new_labels.blank?

    new_labels = Array(new_labels) # Make sure new_labels is an array
    old_labels = label_list.dup
    combined_labels = labels + new_labels
    update!(label_list: combined_labels)
    dispatch_label_update_event(old_labels, label_list)
  end

  private

  def dispatch_label_update_event(old_labels, new_labels)
    return if old_labels == new_labels

    previous_changes_with_labels = { label_list: [old_labels, new_labels] }

    if is_a?(Conversation) && respond_to?(:dispatcher_dispatch)
      dispatcher_dispatch(Conversation::CONVERSATION_UPDATED, previous_changes_with_labels)
    elsif is_a?(Contact)
      Rails.configuration.dispatcher.dispatch(Contact::CONTACT_UPDATED, Time.zone.now, contact: self,
                                                                                       changed_attributes: previous_changes_with_labels)
    end
  end
end
