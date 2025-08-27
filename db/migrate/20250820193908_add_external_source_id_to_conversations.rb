class AddExternalSourceIdToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :external_source_id, :string
  end
end
