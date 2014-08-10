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

		WebsocketRails[:game_updates].trigger(:full_game_state, @game.view_for(player));

		render nothing: true

	end

	def play_card

		data = JSON.parse(message)
    @game = Game.find(data['game_id'])

		Game.transaction do

			user = User.where(id: session[:user]).take
			player = Player.where(game_id: @game.id, user_id: user.id).take
			card = Card.find(data['card_id'])

			if @game.is_legal(player, card)
				@game.play_card(player, card)
				WebsocketRails[:game_updates].trigger(:card_played_event, "Played #{card.name}")
			else
				render json: "Cannot play card", status: 400
			end

		end

		render nothing: true
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

		Game.transaction do

			user = User.where(id: session[:user]).take
			player = Player.where(game_id: @game.id, user_id: user.id).take

			if @game.is_players_turn(player)
				@game.advance_phase
				@game.save
			end

		end

		redirect_to :back

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
