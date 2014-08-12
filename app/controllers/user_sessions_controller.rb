class UserSessionsController < ApplicationController
  skip_before_filter :require_login, except: [:destroy]

  def create
    if @user = login(params[:name], params[:password])
      redirect_to '/'
    else
      flash.now[:alert] = 'Login failed'
      redirect_to :back
    end
  end

  def destroy
    logout
    redirect_to '/'
  end
end

