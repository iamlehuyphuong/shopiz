class AddEcommerceIntegrationToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_reference :inboxes, :ecommerce_integration,
                  foreign_key: { to_table: :integrations_hooks },
                  null: true, index: true
  end
end
