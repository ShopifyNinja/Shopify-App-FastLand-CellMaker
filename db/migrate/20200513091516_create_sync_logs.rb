class CreateSyncLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :sync_logs do |t|
      t.datetime :start_at
      t.datetime :end_at
      t.string :status, null: false, default: :in_progress
    end
  end
end
