class CreateSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :settings do |t|
      t.string :base_url, null: false
      t.string :master_wizard_id, null: false

      t.timestamps
    end
  end
end
