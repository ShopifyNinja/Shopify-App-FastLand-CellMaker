class CreateVirtualHandles < ActiveRecord::Migration[6.0]
  def change
    create_table :virtual_handles do |t|
      t.integer :vh_id, null: false
      t.timestamps
    end
  end
end
