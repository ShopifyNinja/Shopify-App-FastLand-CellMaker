class AddDestinationToVirtualHandle < ActiveRecord::Migration[6.0]
  def change
    add_column :virtual_handles, :destination_id, :integer
  end
end
