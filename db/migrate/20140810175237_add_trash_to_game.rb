class AddTrashToGame < ActiveRecord::Migration
  def change
    add_reference :games, :trash, index: true
  end
end
