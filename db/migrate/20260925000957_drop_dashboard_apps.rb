class DropDashboardApps < ActiveRecord::Migration[7.1]
  def change
    drop_table :dashboard_apps
  end
end
