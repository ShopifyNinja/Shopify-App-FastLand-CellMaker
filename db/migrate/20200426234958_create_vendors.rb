class CreateVendors < ActiveRecord::Migration[6.0]
  def change
    create_table :vendors do |t|
      t.string :vendor, null: false

      t.timestamps
    end

    add_index :vendors, :vendor, unique: true
  end
end
