class AddPagingInfoColumnsToInbox < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :is_load_all_conversation, :boolean
    add_column :inboxes, :next_cursor, :string
  end
end
