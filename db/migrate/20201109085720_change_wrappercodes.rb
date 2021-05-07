class ChangeWrappercodes < ActiveRecord::Migration[6.0]
  def change
    change_column :wrappercodes, :value, :text
  end
end
