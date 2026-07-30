class ChangeDescriptionToTextInCaptainAssistants < ActiveRecord::Migration[7.1]
  def change
    change_column :captain_assistants, :description, :text
  end
end
