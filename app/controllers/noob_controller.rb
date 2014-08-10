class NoobController < WebsocketRails::BaseController

	def initialize_session
		controller_store[:message_count] = 0
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
			card = Card.find(data['card_id'])

			if @game.is_legal(player, card)
				events = []
				@game.play_card(player, card, events)
				@game.players.each do |p|
					WebsocketRails["game_updates_#{@game.id}"].trigger("update_game_state_#{p.id}", events)
				end
			else
				render json: "Cannot play card", status: 400
			end

		end
	end

	def buy_card

		begin
			Game.transaction do

				user = User.where(id: session[:user]).take
				player = Player.where(game_id: @game.id, user_id: user.id).take
				supply = Supply.find(params.require(:supply_id))

				if @game.is_players_turn(player) and @game.phase == 'buy'
					@game.buy_card(player, supply)
				end

			end

			render json: {}, :status => 200
		rescue Exception => e
			render json: {error: e.message}, :status => 500
			raise e
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
				@game.players.each do |p|
					WebsocketRails["game_updates_#{@game.id}"].trigger("update_game_state_#{p.id}", events)
				end
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
