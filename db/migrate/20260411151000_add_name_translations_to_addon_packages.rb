class AddNameTranslationsToAddonPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :addon_packages, :name_en, :string
    add_column :addon_packages, :name_vi, :string
  end
end
