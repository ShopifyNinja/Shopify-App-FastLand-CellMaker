class CreateVh < ActiveRecord::Migration[6.0]
  def change
    create_table :vhs do |t|
      t.string :name, null: false
      t.integer :exp1_type, null: false
      t.string :exp1_value, null: false
      t.integer :exp2_type, null: false
      t.string :exp2_value, null: false
      t.integer :condition, null: false
    end
  end
end
