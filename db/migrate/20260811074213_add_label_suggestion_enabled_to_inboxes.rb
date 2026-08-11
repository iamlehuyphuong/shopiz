class AddLabelSuggestionEnabledToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :label_suggestion_enabled, :boolean, default: false, null: false
  end
end
