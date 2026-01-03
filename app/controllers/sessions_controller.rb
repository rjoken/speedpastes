class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by("lower(email) = ?", params[:email].to_s.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path
  end
end
