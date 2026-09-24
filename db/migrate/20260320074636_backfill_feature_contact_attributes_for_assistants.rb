class BackfillFeatureContactAttributesForAssistants < ActiveRecord::Migration[7.1]
  # Only backfill assistants on accounts with captain_integration enabled.
  def up
    return unless ChatwootApp.enterprise?

    Account.feature_captain_integration.find_each do |account|
      account.captain_assistants.each do |assistant|
        next if assistant.feature_contact_attributes.present?

        assistant.update(feature_contact_attributes: true)
      end
    end
  end

  def down
    return unless ChatwootApp.enterprise?

    Account.feature_captain_integration.find_each do |account|
      account.captain_assistants.each do |assistant|
        next if assistant.feature_contact_attributes.blank?

        assistant.update(feature_contact_attributes: nil)
      end
    end
  end
end
