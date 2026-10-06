module Admin
  class UsersController < BaseController
    def index
      @users = UserPresenter.wrap User.order(:email)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_users_path, notice: "User was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])

      if @user.update(user_params)
        redirect_to admin_users_path, notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      user = User.find(params[:id])
      return redirect_to admin_users_path, alert: "You cannot delete yourself." if user == current_user

      user.destroy!
      redirect_to admin_users_path, notice: "User was successfully deleted."
    end

    private

    # Admins cannot revoke their own admin flag, so at least one admin always remains.
    def user_params
      attributes = %i[first_name last_name email password password_confirmation]
      attributes << :admin unless @user == current_user
      params.require(:user).permit(attributes)
    end
  end
end
