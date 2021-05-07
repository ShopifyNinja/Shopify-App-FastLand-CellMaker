class ChangeSettings < ActiveRecord::Migration[6.0]
  def change
    change_column :settings, :master_wizard_id, :integer, null: true
  end
end
