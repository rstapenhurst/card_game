class HomeController < ApplicationController
	def main 
		if session[:user].nil?
			render :login_page
		else
			@user = User.where(id: session[:user]).take
			render :index
		end
	end

	def login
		@user = User.where(name: params.require(:username)).take
		if @user.nil?
			redirect_to action: main, :status => 500 and return
		end
		session[:user] = @user.id
		redirect_to action: :main
	end

	def logout
		session[:user] = nil
		redirect_to action: :main
	end

	def play
		@game = Game.find(params[:id])
		@user = User.where(id: session[:user]).take
		@u = Player.where(game_id: @game.id, user_id: @user.id).take
		render :play
	end

	def play
		@game = Game.find(params[:id])
		@user = User.where(id: session[:user]).take
		@u = Player.where(game_id: @game.id, user_id: @user.id).take
		render :play2
	end
end
