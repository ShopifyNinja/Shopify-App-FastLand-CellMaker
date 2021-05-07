class CreateTemplate < ActiveRecord::Migration[6.0]
  def change
    create_table :templates do |t|
      t.string :name, null: false
      t.integer :wizard_id, null: false
      t.boolean :default_value, default: false
    end

    execute "insert into templates (name, wizard_id, default_value) values ('Part', 722, false)"
    execute "insert into templates (name, wizard_id, default_value) values ('Accessories', 732, false)"
    execute "insert into templates (name, wizard_id, default_value) values ('Banner', 722, false)"
    execute "insert into templates (name, wizard_id, default_value) values ('Features', 722, true)"
  end
end
