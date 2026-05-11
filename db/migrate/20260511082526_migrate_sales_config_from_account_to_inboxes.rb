class MigrateSalesConfigFromAccountToInboxes < ActiveRecord::Migration[7.0]
  def up
    Account.where("settings ? 'sales_order_notification_templates' OR settings ? 'sales_ai_allow_create_order'").find_each do |account|
      templates = account.settings['sales_order_notification_templates']
      ai_allow = account.settings['sales_ai_allow_create_order']

      next if templates.blank? && ai_allow.nil?

      sales_config = {}
      sales_config['order_notification_templates'] = templates if templates.present?
      sales_config['ai_allow_create_order'] = ai_allow unless ai_allow.nil?

      account.inboxes.update_all(sales_config: sales_config)
    end
  end

  def down
    # No-op: Account-level data still exists as backup
  end
end
