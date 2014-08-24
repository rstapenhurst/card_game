class AddPlayerToCardPlayState < ActiveRecord::Migration
  def change
		add_reference :card_play_states, :player
  end
end
