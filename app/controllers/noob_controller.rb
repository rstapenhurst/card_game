class NoobController < WebsocketRails::BaseController

	def initialize_session
		controller_store[:message_count] = 0
	end

	def filter_log(events, is_current_player)
		output = []
		index = @game.event_index
		events.each do |event|
			index += 1
			output_event = {}
			if is_current_player
				output_event.merge!({
					player_log: event[:player_log]
				}) if event[:player_log]
			end
			output_event.merge!({
				all_log: event[:all_log]
			}) if event[:all_log]
			output_event.merge!({
				event_index: index
			})
			output << output_event
		end
		return output
	end

	def broadcast_log(game, player, events)
		@game.players.each do |p|
			WebsocketRails["game_updates_#{@game.id}"].trigger("update_game_state_#{p.id}",
																												 filter_log(events, player.id == p.id))
		end
		@game.event_index += events.size
		@game.save
	end

	def game_fetch

		puts "Game fetch called"
		data = JSON.parse(message)
    @game = Game.find(data['game_id'])

		user = User.where(id: session[:user]).take
		player = Player.where(game_id: @game.id, user_id: user.id).take

		WebsocketRails["game_updates_#{@game.id}"].trigger("full_game_state_#{player.id}", @game.view_for(player))
	end

	def play_card

		data = JSON.parse(message)
    @game = Game.find(data['game_id'])

		Game.transaction do

			user = User.where(id: session[:user]).take
			player = Player.where(game_id: @game.id, user_id: user.id).take
			card = Card.find(data['data']['card_id'])

			if @game.is_legal(player, card)
				events = []
				@game.play_card(player, card, events)
				broadcast_log(@game, player, events)
			else
				render json: "Cannot play card", status: 400
			end

		end
	end

	def buy_card

		data = JSON.parse(message)
    @game = Game.find(data['game_id'])
		supply = Supply.find(data['data']['supply_id'])

		Game.transaction do

			user = User.where(id: session[:user]).take
			player = Player.where(game_id: @game.id, user_id: user.id).take

			if @game.is_players_turn(player) and @game.phase == 'buy'
				events = []
				@game.buy_card(player, supply, events)
				broadcast_log(@game, player, events)
			end

		end

	end

	def advance_phase

		data = JSON.parse(message)
    @game = Game.find(data['game_id'])

		Game.transaction do

			user = User.where(id: session[:user]).take
			player = Player.where(game_id: @game.id, user_id: user.id).take

			if @game.is_players_turn(player)
				events = []
				@game.advance_phase(events)
				@game.save
				broadcast_log(@game, player, events)
			end

		end
	end

  private
    def set_game(data)
      @game = Game.find(data[:game_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.require(:game).permit(:name, :phase, :turn)
    end

end
