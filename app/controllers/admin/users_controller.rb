module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[edit update]
    before_action :redirect_own_user_to_account, only: %i[edit update]

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
    end

    def update
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

    def set_user
      @user = User.find(params[:id])
    end

    # The account page requires the current password for email and password changes and
    # cannot revoke the admin flag, so at least one admin always remains.
    def redirect_own_user_to_account
      redirect_to edit_account_path if @user == current_user
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :admin)
    end
  end
end
