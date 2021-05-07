class AddVhToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :vh_id, :integer
  end
end
