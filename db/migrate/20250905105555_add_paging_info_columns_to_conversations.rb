class AddPagingInfoColumnsToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :is_load_all_message, :boolean
    add_column :conversations, :next_cursor, :string
  end
end
