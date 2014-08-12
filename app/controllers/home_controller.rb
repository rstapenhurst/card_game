class HomeController < ApplicationController
  skip_before_filter :require_login, only: [:main]

	def main 
		if current_user.nil?
			render :login_page
		else
			@user = current_user
			render :index
		end
	end

	def play
		@game = Game.find(params[:id])
    @user  = current_user
		@u = Player.where(game_id: @game.id, user_id: @user.id).take
		render :play
	end

	def play2
		@game = Game.find(params[:id])
		@user = current_user
		@u = Player.where(game_id: @game.id, user_id: @user.id).take
		@dont_spacer = 1
		render :play3
	end
end
