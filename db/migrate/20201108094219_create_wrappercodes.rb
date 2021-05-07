class CreateWrappercodes < ActiveRecord::Migration[6.0]
  def change
    create_table :wrappercodes do |t|
      t.string :value
      t.integer :destination_id
      t.integer :used
      t.timestamps
    end
  end
end
