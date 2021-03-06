class NoobController < WebsocketRails::BaseController

	def initialize_session
	end

	def filter_log(game, events, log_player, current_player)
		output = []
		index = game.event_index
		events.each do |event|
			index += 1
			output_event = event.slice(:type, :all_log, log_player.id == current_player.id ? :player_log : :opponent_log)
			if event.has_key?(:logs_by_id)
				log_by_id = event[:logs_by_id].select{|log| log_player.id == log[:owner_id]}
				if log_by_id.count() == 1
					output_event.merge!({
						player_log: log_by_id[0]
					})
				end
			end
      output_event[:event_index] = index
			output << output_event
		end
		return output
	end

	def broadcast_log(game, player, events)
		game.players.each do |p|
			WebsocketRails["game_updates_#{game.id}"].trigger("update_game_state_#{p.id}",
																												 filter_log(game, events, p, player))
		end
		index = game.event_index
		events.each do |event|
			index += 1
			event_model = Event.create(event_index: index, event: event.to_s, game: game)
		end
		game.event_index = index
		game.save
	end

	def game_fetch

		data = JSON.parse(message)
    game = Game.find(data['game_id'])

		user = current_user
		player = Player.where(game_id: game.id, user_id: user.id).take

		WebsocketRails["game_updates_#{game.id}"].trigger("full_game_state_#{player.id}", game.view_for(player))
	end

	def play_card

		data = JSON.parse(message)
    game = Game.find(data['game_id'])

		Game.transaction do

			user = current_user
			player = Player.where(game_id: game.id, user_id: user.id).take
			card = Card.find(data['data']['card_id'])

			if game.is_legal(player, card) and !game.has_dialog
				events = []
				game.play_card(player, card, events)
				broadcast_log(game, player, events)
			end
		end
	end

	def buy_card

		data = JSON.parse(message)
    game = Game.find(data['game_id'])
		supply = Supply.find(data['data']['supply_id'])

		Game.transaction do

			user = current_user
			player = Player.where(game_id: game.id, user_id: user.id).take

			if game.is_players_turn(player) and game.phase == 'buy' and !game.has_dialog
				events = []
				game.buy_card(player, supply, events)
				broadcast_log(game, player, events)
			end

		end

	end

    def chat
      data = JSON.parse(message)
      game = Game.find(data['game_id'])

      WebsocketRails["game_updates_#{game.id}"].trigger("game_chat_event", {
        from: current_user.name,
        message: data['data']['message']
      })
    end
      

	def advance_phase

		data = JSON.parse(message)
    game = Game.find(data['game_id'])

		Game.transaction do

			user = current_user
			player = Player.where(game_id: game.id, user_id: user.id).take

			if game.is_players_turn(player)
				events = []
				game.advance_phase(events)
				game.save
				broadcast_log(game, player, events)
			end

		end
	end

	def respond_dialog

		data = JSON.parse(message)
		game = Game.find(data['game_id'])
		dialog = Dialog.find(data['data']['dialog_id'])

		Game.transaction do

			user = current_user
			player = Player.where(game_id: game.id, user_id: user.id).take
			if dialog.stage > 0 and dialog.active_player == player
				special = dialog.special_type.constantize.new()
				events = []
				special.process_response(game, player, dialog, data['data'], events)
				broadcast_log(game, player, events)
			end

		end

	end

	def client_connected

		user = current_user
		Player.where(user_id: user.id).pluck(:id).each do |player_id|
			player = Player.find(player_id)
			player.connected = true
			player.save
			game = Game.find(player.game_id)
			events = []
			events << {
				type: "player_connected",
				all_log: {
					name: player.name,
					id: player.id
				}
			}

			broadcast_log(game, player, events)
		end

	end

	def client_disconnected

		user = current_user
		Player.where(user_id: user.id).pluck(:id).each do |player_id|
			player = Player.find(player_id)
			player.connected = false
			player.save
			game = Game.find(player.game_id)
			events = []
			events << {
				type: "player_disconnected",
				all_log: {
					name: player.name,
					id: player.id
				}
			}

			broadcast_log(game, player, events)
		end

	end

  private
    def set_game(data)
      game = Game.find(data[:game_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.require(:game).permit(:name, :phase, :turn)
    end

end
