class CreateDestinations < ActiveRecord::Migration[6.0]
  def change
    create_table :destinations do |t|
      t.string :destination, null: false

      t.timestamps
    end

    add_index :destinations, :destination, unique: true
  end
end
