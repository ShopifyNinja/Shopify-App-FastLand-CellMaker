class CreateProductHandles < ActiveRecord::Migration[6.0]
  def change
    create_table :product_handles do |t|
      t.string :handle, null: false
      t.integer :destination_id, null: false
      t.integer :product_id

      t.timestamps
    end

    add_index :product_handles, [:handle, :destination_id], unique: true
  end
end
