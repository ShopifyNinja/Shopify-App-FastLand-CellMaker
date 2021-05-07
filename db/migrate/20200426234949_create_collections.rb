class CreateCollections < ActiveRecord::Migration[6.0]
  def change
    create_table :collections do |t|
      t.string :title, null: false

      t.timestamps
    end

    add_index :collections, :title, unique: true
  end
end
