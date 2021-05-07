class ChangeSchedule < ActiveRecord::Migration[6.0]
  def change
    remove_column :schedules, :times
    add_column :schedules, :timezone_id, :integer
    add_column :schedules, :start_time, :string
    add_column :schedules, :frequency, :integer
  end

  execute "DELETE FROM schedules"
end
