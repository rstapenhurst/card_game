class AddEventIndexToGame < ActiveRecord::Migration
  def change
		add_column :games, :event_index, :integer
  end
end
