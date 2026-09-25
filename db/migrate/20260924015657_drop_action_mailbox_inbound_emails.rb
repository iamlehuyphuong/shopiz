class DropActionMailboxInboundEmails < ActiveRecord::Migration[7.1]
  def change
    drop_table :action_mailbox_inbound_emails if table_exists?(:action_mailbox_inbound_emails)
  end
end
