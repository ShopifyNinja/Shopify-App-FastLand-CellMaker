class CreateThemes < ActiveRecord::Migration[6.0]
  def change
    create_table :themes do |t|
      t.bigint :shopify_theme_id, null: false
      t.string :name, null: false
      t.string :role, null: false
      t.boolean :installed, null: false, default: false

      t.datetime :created_at, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
