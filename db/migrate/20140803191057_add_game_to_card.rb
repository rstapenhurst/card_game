class AddGameToCard < ActiveRecord::Migration
  def change
		add_reference :cards, :game
  end
end
