class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by("lower(email) = ?", params[:email].to_s.downcase)
    if user&.anonymized_at.present?
      flash.now[:alert] = "Invalid email or password"
      return render :new, status: :unprocessable_entity
    end
    if user&.valid_password?(params[:password])
      sign_in(user)
      redirect_to root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to root_path
  end
end
