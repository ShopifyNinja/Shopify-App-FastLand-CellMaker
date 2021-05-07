class AddFieldsToDestination < ActiveRecord::Migration[6.0]
  def change
    add_column :destinations, :purpose_type, :integer, default: 0
    add_column :destinations, :dynamic_html, :text
  end
end
