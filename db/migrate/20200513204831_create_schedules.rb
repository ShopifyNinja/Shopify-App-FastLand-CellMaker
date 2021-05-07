class CreateSchedules < ActiveRecord::Migration[6.0]
  def change
    create_table :schedules do |t|
      t.string :times, null: false

      t.timestamps
    end
  end
end
