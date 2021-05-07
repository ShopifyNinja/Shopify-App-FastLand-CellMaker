class AddWrappercodeToPages < ActiveRecord::Migration[6.0]
  def change
    add_column :pages, :wrappercode, :text
  end
end
