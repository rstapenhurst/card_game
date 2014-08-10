p
require 'reloader/sse'

class GamesController < ApplicationController
	include ActionController::Live
  before_action :set_game, only: [:show, :edit, :update, :destroy, :add_player, :play_card, :advance_phase, :buy_card, :stream]

  # GET /games
  # GET /games.json
  def index
    @games = Game.all
  end

  # GET /games/1
  # GET /games/1.json
  def show
  end

  # GET /games/new
  def new
    @game = Game.new
  end

  # GET /games/1/edit
  def edit
  end

	def stream
		render :stream
	end

  # POST /games
  # POST /games.json
  def create
    @game = Game.new(game_params)
		@game.phase = 'init'
		@game.turn = 0
		@game.trash = CardPile.create(name: "Trash");

    respond_to do |format|
      if @game.save
        format.html { redirect_to :back }
        format.json { render :show, status: :created, location: @game }
      else
        format.html { render :new }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
    respond_to do |format|
      if @game.update(game_params)
        format.html { redirect_to @game, notice: 'Game was successfully updated.' }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    @game.destroy
    respond_to do |format|
      format.html { redirect_to games_url, notice: 'Game was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

	def add_player

		Game.transaction do

			@game.create_player_for_user(params.require(:user_id))

		end

		redirect_to :back
	end

	def play_card

		Game.transaction do

			user = User.where(id: session[:user]).take
			player = Player.where(game_id: @game.id, user_id: user.id).take
			card = Card.find(params.require(:card_id))

			if @game.is_legal(player, card)
				@game.play_card(player, card)
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
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.require(:game).permit(:name, :phase, :turn)
    end

end
