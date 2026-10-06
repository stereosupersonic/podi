class AccountsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.assign_attributes(account_params)

    if @user.save(context: :account_update)
      redirect_to edit_account_path, notice: "Account was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def account_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation,
                                 :current_password)
  end
end
