class AddAttributesToDialog < ActiveRecord::Migration
  def change
    add_reference :dialogs, :game, index: true
    add_reference :dialogs, :active_player, index: true
    add_column :dialogs, :stage, :integer
    add_column :dialogs, :special_type, :string
    add_column :dialogs, :state, :text
  end
end
