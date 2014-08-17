class AddConnectedToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :connected, :boolean
  end
end
