class CreateProducts < ActiveRecord::Migration[6.0]
  def change
    create_table :products do |t|
      t.integer :page_id, null: false
      t.integer :destination_id, null: false
      t.integer :collection_id
      t.integer :vendor_id
      t.integer :tag_id
      t.integer :product_handle_id

      t.timestamps
    end

    add_index :products, [:destination_id, :collection_id], unique: true, where: "collection_id IS NOT NULL"
    add_index :products, [:destination_id, :vendor_id], unique: true, where: "vendor_id IS NOT NULL"
    add_index :products, [:destination_id, :tag_id], unique: true, where: "tag_id IS NOT NULL"
    add_index :products, [:destination_id, :product_handle_id], unique: true, where: "product_handle_id IS NOT NULL"
  end
end
