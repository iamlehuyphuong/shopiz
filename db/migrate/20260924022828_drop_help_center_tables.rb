class DropHelpCenterTables < ActiveRecord::Migration[7.1]
  def change
    remove_reference :inboxes, :portal, foreign_key: true if column_exists?(:inboxes, :portal_id)
    drop_table :articles, if_exists: true
    drop_table :categories, if_exists: true
    drop_table :portals, if_exists: true
    drop_table :portal_members, if_exists: true
    drop_table :related_categories, if_exists: true
  end
end
