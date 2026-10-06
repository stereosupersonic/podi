module Users
  class SessionsController < ApplicationController
    rate_limit to: 10, within: 3.minutes, only: :create, with: :render_too_many_attempts

    def new
      # Render sign in form
    end

    def create
      user = User.find_by(email: params[:email])

      if user&.authenticate(params[:password])
        reset_session
        session[:user_id] = user.id
        redirect_to admin_statistics_path, notice: "Signed in successfully"
      else
        flash.now[:alert] = "Invalid email or password"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to root_path, notice: "Signed out successfully"
    end

    private

    def render_too_many_attempts
      flash.now[:alert] = "Too many sign-in attempts. Please try again in a few minutes."
      render :new, status: :too_many_requests
    end
  end
end
