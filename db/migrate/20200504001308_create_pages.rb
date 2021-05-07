class CreatePages < ActiveRecord::Migration[6.0]
  def change
    create_table :pages do |t|
      t.string :base_url, null: false
      t.string :html, null: false
      t.string :styles, null: false
      t.text :images, null: false

      t.timestamps
    end

    add_index :pages, [:base_url, :html, :styles, :images], length: { images: 255 }, unique: true
  end
end
