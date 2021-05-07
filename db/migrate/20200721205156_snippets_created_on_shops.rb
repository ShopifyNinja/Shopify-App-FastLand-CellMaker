class SnippetsCreatedOnShops < ActiveRecord::Migration[6.0]
  def change
    add_column :shops, :snippets_created, :integer, null: false, default: 0
  end
end
