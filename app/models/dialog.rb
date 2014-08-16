class Dialog < ActiveRecord::Base

	belongs_to :game
	belongs_to :active_player, class_name: "Player"

end
