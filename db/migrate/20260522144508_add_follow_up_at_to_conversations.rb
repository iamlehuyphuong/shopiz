class AddFollowUpAtToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :follow_up_at, :datetime
    add_index :conversations, :follow_up_at
  end
end
