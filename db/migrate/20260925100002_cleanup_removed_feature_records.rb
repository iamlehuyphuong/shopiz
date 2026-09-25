class CleanupRemovedFeatureRecords < ActiveRecord::Migration[7.1]
  def up
    # Help Center was removed, so custom roles can no longer hold this permission
    execute "UPDATE custom_roles SET permissions = array_remove(permissions, 'knowledge_base_manage')"
    # Integration apps that no longer exist in config/integration/apps.yml
    execute "DELETE FROM integrations_hooks WHERE app_id IN ('dyte', 'dashboard_apps')"
    # campaign_type 2 was `voice`
    execute 'DELETE FROM campaigns WHERE campaign_type = 2'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
