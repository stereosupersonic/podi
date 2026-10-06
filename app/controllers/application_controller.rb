class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound, with: :render404

  def render404
    respond_to do |format|
      format.html { render file: Rails.root.join("public/404.html"), layout: false, status: :not_found }
      format.any { head :not_found }
    end
  end

  helper_method :current_setting, :current_user, :user_signed_in?

  # The layout shows admin links to logged-in users, so a page cached while logged in must not be
  # revalidated after logout, and vice versa.
  etag { current_user&.id }

  def current_setting
    @current_setting ||= Setting.current
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    redirect_to login_path, alert: "Please sign in to continue" unless user_signed_in?
  end

  protected

  def authorize_admin
    redirect_to "/", alert: "Access Denied" unless current_user&.admin?
  end
end
